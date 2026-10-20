import AppKit
import VibeScreenCore
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var container: AppContainer
    let openMainWindow: () -> Void
    @State private var values: [String: String] = [:]
    @State private var isRefreshing = false
    @State private var isApplying = false

    private static let controls = LGControlCatalog.controls(in: .gameBar)
        + LGControlCatalog.controls.filter { $0.id == "audioVolume" }

    private var firstDevice: TVDeviceDescriptor? {
        container.devices.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            tvControls
            Divider()
            footer
        }
        .padding(12)
        .frame(width: 360)
        .onAppear {
            Task { await refreshValues() }
        }
    }

    @ViewBuilder
    private var tvControls: some View {
        if let device = firstDevice {
            if device.kind == .lgWebOS {
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text("Game Bar")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        if isRefreshing || isApplying {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Button {
                            Task { await refreshValues() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.borderless)
                        .help("Read the five values from \(device.name)")
                        .accessibilityLabel("Read Game Bar values from TV")
                        .disabled(isRefreshing || isApplying)
                    }

                    ForEach(Self.controls) { control in
                        sliderRow(control, device: device)
                    }
                }
            } else {
                Label(
                    "The first TV is Samsung. Game Bar sliders require an LG WebOS TV.",
                    systemImage: "info.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        } else {
            Label("Add an LG TV to use the five quick sliders.", systemImage: "tv.badge.plus")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func sliderRow(_ control: LGControlDescriptor, device: TVDeviceDescriptor) -> some View {
        let bounds = range(for: control)
        return HStack(spacing: 8) {
            Text(control.title)
                .font(.caption)
                .lineLimit(1)
                .frame(width: 124, alignment: .leading)
            Slider(
                value: sliderBinding(for: control, defaultValue: bounds.lowerBound),
                in: Double(bounds.lowerBound) ... Double(bounds.upperBound),
                onEditingChanged: { editing in
                    if !editing {
                        apply(control, to: device)
                    }
                }
            )
            .accessibilityLabel(control.title)
            .accessibilityValue(displayedValue(for: control))
            Text(displayedValue(for: control))
                .font(.caption.monospacedDigit())
                .frame(width: 36, alignment: .trailing)
                .contentShape(Rectangle())
                .overlay {
                    MouseButtonClickOverlay(
                        onLeftClick: { adjust(control, by: 5, on: device) },
                        onRightClick: { adjust(control, by: -5, on: device) }
                    )
                }
                .help("Left-click to increase by 5%; right-click to decrease by 5%")
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Left-click increases by 5 percent; right-click decreases by 5 percent")
        }
        .disabled(isRefreshing || isApplying)
    }

    private var footer: some View {
        HStack {
            Button {
                openMainWindow()
            } label: {
                Label("Open VibeScreen", systemImage: "arrow.up.forward.app")
            }
            Spacer()
            Button("Quit") {
                container.prepareForTermination()
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .controlSize(.small)
    }

    private func range(for control: LGControlDescriptor) -> ClosedRange<Int> {
        guard case let .range(minimum, maximum) = control.valueKind else { return 0 ... 100 }
        return minimum ... maximum
    }

    private func sliderBinding(for control: LGControlDescriptor, defaultValue: Int) -> Binding<Double> {
        Binding(
            get: { Double(Int(values[control.id] ?? control.defaultValue) ?? defaultValue) },
            set: { values[control.id] = String(Int($0.rounded())) }
        )
    }

    private func displayedValue(for control: LGControlDescriptor) -> String {
        "\(Int(values[control.id] ?? control.defaultValue) ?? range(for: control).lowerBound)%"
    }

    private func adjust(_ control: LGControlDescriptor, by delta: Int, on device: TVDeviceDescriptor) {
        guard !isRefreshing, !isApplying else { return }
        let bounds = range(for: control)
        let current = Int(values[control.id] ?? control.defaultValue) ?? bounds.lowerBound
        let adjusted = min(bounds.upperBound, max(bounds.lowerBound, current + delta))
        guard adjusted != current else { return }
        values[control.id] = String(adjusted)
        apply(control, to: device)
    }

    private func refreshValues() async {
        guard let device = firstDevice, device.kind == .lgWebOS, !isRefreshing, !isApplying else { return }
        isRefreshing = true
        let current = await container.loadLGLiveValues(for: device)
        values.merge(current) { _, new in new }
        isRefreshing = false
    }

    private func apply(_ control: LGControlDescriptor, to device: TVDeviceDescriptor) {
        guard !isRefreshing, !isApplying else { return }
        isApplying = true
        let value = values[control.id] ?? control.defaultValue
        Task {
            let succeeded = await container.applyLGControl(control, value: value, to: device)
            if succeeded {
                let current = await container.loadLGLiveValues(for: device)
                values.merge(current) { _, new in new }
            }
            isApplying = false
        }
    }
}
