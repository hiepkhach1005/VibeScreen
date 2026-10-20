import VibeScreenCore
import Foundation
import SwiftUI

@MainActor
final class SystemMonitorViewModel: ObservableObject {
    @Published private(set) var snapshot: SystemMonitorSnapshot?
    @Published private(set) var errorMessage: String?

    private let sampler: any SystemMonitorSampling
    private var samplingTask: Task<Void, Never>?

    init(sampler: any SystemMonitorSampling = MacSystemMonitorSampler()) {
        self.sampler = sampler
    }

    deinit {
        samplingTask?.cancel()
    }

    func start(intervalMilliseconds: Int) {
        stop()
        samplingTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.refresh()
                do {
                    try await Task.sleep(for: .milliseconds(intervalMilliseconds))
                } catch {
                    return
                }
            }
        }
    }

    func stop() {
        samplingTask?.cancel()
        samplingTask = nil
    }

    func refresh() async {
        do {
            snapshot = try await sampler.sample()
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct SystemMonitorView: View {
    @ObservedObject var container: AppContainer
    @StateObject private var model = SystemMonitorViewModel()

    private let columns = [
        GridItem(.adaptive(minimum: 190, maximum: 300), spacing: 12, alignment: .top)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if let errorMessage = model.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .accessibilityLabel("System monitor error: \(errorMessage)")
                }

                publicAPINotice

                processorSection
                temperatureSection
                storageSection
                networkSection
                coolingSection
                powerSection
            }
            .padding(24)
            .frame(maxWidth: 1_050, alignment: .leading)
        }
        .navigationTitle("Monitor")
        .onAppear {
            model.start(intervalMilliseconds: container.nativeSettings.systemMonitorIntervalMilliseconds)
        }
        .onChange(of: container.nativeSettings.systemMonitorIntervalMilliseconds) { _, interval in
            model.start(intervalMilliseconds: interval)
        }
        .onDisappear {
            model.stop()
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 5) {
                Text("System Monitor")
                    .font(.largeTitle.bold())
                if let capturedAt = model.snapshot?.capturedAt {
                    Text("Updated \(capturedAt.formatted(date: .omitted, time: .standard))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Collecting the first sample…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                Task { await model.refresh() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .help("Collect a system monitor sample now")
        }
    }

    private var processorSection: some View {
        monitorGroup("Utilization", systemImage: "gauge.with.dots.needle.67percent") {
            MetricTile(
                title: "CPU used",
                value: percent(model.snapshot?.cpuUsagePercent),
                detail: model.snapshot?.cpuUsagePercent == nil ? "Waiting for the next sample" : "Whole-system processor load",
                systemImage: "cpu"
            )
            MetricTile(
                title: "GPU used",
                value: "Unavailable",
                detail: publicSensorLimitation,
                systemImage: "rectangle.3.group"
            )
            MetricTile(
                title: "Memory used",
                value: memoryValue,
                detail: memoryDetail,
                systemImage: "memorychip"
            )
            MetricTile(
                title: "CPU cores",
                value: processorCount,
                detail: "Active / logical processors reported by ProcessInfo",
                systemImage: "square.grid.3x3"
            )
            MetricTile(
                title: "System uptime",
                value: uptime,
                detail: "Time since the last macOS boot",
                systemImage: "clock"
            )
            MetricTile(
                title: "Thermal pressure",
                value: thermalPressure,
                detail: "The public macOS system thermal state",
                systemImage: "thermometer.medium"
            )
        }
    }

    private var temperatureSection: some View {
        monitorGroup("Temperatures", systemImage: "thermometer.high") {
            unavailableSensor("CPU temperature", systemImage: "cpu")
            unavailableSensor("GPU temperature", systemImage: "rectangle.3.group")
            unavailableSensor("Memory temperature", systemImage: "memorychip")
            unavailableSensor("SSD temperature", systemImage: "internaldrive")
        }
    }

    private var storageSection: some View {
        monitorGroup("Storage", systemImage: "internaldrive") {
            MetricTile(
                title: "Startup volume",
                value: storageValue,
                detail: storageDetail,
                systemImage: "internaldrive"
            )
            MetricTile(
                title: "SSD health",
                value: "Unavailable",
                detail: "SMART health is not exposed through a documented public macOS API",
                systemImage: "checkmark.shield"
            )
        }
    }

    private var networkSection: some View {
        monitorGroup("Network", systemImage: "network") {
            MetricTile(
                title: "Download",
                value: rate(model.snapshot?.networkDownloadBytesPerSecond),
                detail: "Across active non-loopback interfaces",
                systemImage: "arrow.down.circle"
            )
            MetricTile(
                title: "Upload",
                value: rate(model.snapshot?.networkUploadBytesPerSecond),
                detail: "Across active non-loopback interfaces",
                systemImage: "arrow.up.circle"
            )
        }
    }

    private var coolingSection: some View {
        monitorGroup("Cooling", systemImage: "fan") {
            MetricTile(
                title: "Fan speed",
                value: "Unavailable",
                detail: publicSensorLimitation,
                systemImage: "fan"
            )
        }
    }

    private var powerSection: some View {
        monitorGroup("Power", systemImage: "bolt.fill") {
            MetricTile(
                title: "Power source / DC-in",
                value: powerSource,
                detail: "Current source reported by IOKit",
                systemImage: "powerplug"
            )
            MetricTile(
                title: "Voltage",
                value: measurement(model.snapshot?.voltageVolts, unit: "V"),
                detail: "Battery value when the hardware reports it",
                systemImage: "bolt"
            )
            MetricTile(
                title: "Current",
                value: measurement(model.snapshot?.currentAmps, unit: "A"),
                detail: "Battery charge or discharge current",
                systemImage: "waveform.path.ecg"
            )
            MetricTile(
                title: "Battery power flow",
                value: measurement(model.snapshot?.estimatedBatteryFlowWatts, unit: "W"),
                detail: "Estimated as |voltage × current|; not total system power",
                systemImage: "battery.75percent"
            )
            MetricTile(
                title: "Total system power",
                value: "Unavailable",
                detail: "Live whole-system watts require hardware telemetry outside public macOS APIs",
                systemImage: "bolt.horizontal"
            )
            MetricTile(
                title: "Adapter rating",
                value: measurement(model.snapshot?.adapterRatedWatts, unit: "W", decimals: 0),
                detail: "Adapter capacity, not live system consumption",
                systemImage: "powerplug.fill"
            )
        }
    }

    private func monitorGroup<Content: View>(
        _ title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        GroupBox {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                content()
            }
            .padding(.top, 4)
        } label: {
            Label(title, systemImage: systemImage)
                .font(.headline)
        }
    }

    private var publicAPINotice: some View {
        Label(
            "Monitor uses documented macOS APIs. SMC-only sensors and fan control are not enabled.",
            systemImage: "info.circle"
        )
        .font(.callout)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel("Monitor uses documented macOS APIs. SMC-only sensors and fan control are unavailable.")
    }

    private func unavailableSensor(_ title: String, systemImage: String) -> some View {
        MetricTile(
            title: title,
            value: "Unavailable",
            detail: publicSensorLimitation,
            systemImage: systemImage
        )
    }

    private var publicSensorLimitation: String {
        "No documented public macOS system sensor API"
    }

    private var memoryValue: String {
        guard let snapshot = model.snapshot, snapshot.memoryTotalBytes > 0 else { return "Collecting…" }
        return bytes(snapshot.memoryUsedBytes)
    }

    private var memoryDetail: String {
        guard let snapshot = model.snapshot, snapshot.memoryTotalBytes > 0 else {
            return "Physical memory in-use estimate"
        }
        let percentage = Double(snapshot.memoryUsedBytes) / Double(snapshot.memoryTotalBytes) * 100
        return "\(percentage.formatted(.number.precision(.fractionLength(0))))% of \(bytes(snapshot.memoryTotalBytes))"
    }

    private var processorCount: String {
        guard let snapshot = model.snapshot,
              snapshot.processorCount > 0 else { return "Collecting…" }
        let active = snapshot.activeProcessorCount > 0
            ? snapshot.activeProcessorCount
            : snapshot.processorCount
        return "\(active) / \(snapshot.processorCount)"
    }

    private var uptime: String {
        guard let snapshot = model.snapshot, snapshot.systemUptimeSeconds > 0 else {
            return "Collecting…"
        }
        let totalMinutes = Int(snapshot.systemUptimeSeconds / 60)
        let days = totalMinutes / (24 * 60)
        let hours = (totalMinutes / 60) % 24
        let minutes = totalMinutes % 60
        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    private var storageValue: String {
        guard let snapshot = model.snapshot, snapshot.storageTotalBytes > 0 else {
            return "Collecting…"
        }
        let used = snapshot.storageTotalBytes > snapshot.storageAvailableBytes
            ? snapshot.storageTotalBytes - snapshot.storageAvailableBytes
            : 0
        return bytes(used)
    }

    private var storageDetail: String {
        guard let snapshot = model.snapshot, snapshot.storageTotalBytes > 0 else {
            return "Startup volume capacity"
        }
        let percentage = Double(snapshot.storageTotalBytes - min(
            snapshot.storageTotalBytes,
            snapshot.storageAvailableBytes
        )) / Double(snapshot.storageTotalBytes) * 100
        return "\(percentage.formatted(.number.precision(.fractionLength(0))))% used of \(bytes(snapshot.storageTotalBytes))"
    }

    private var thermalPressure: String {
        guard let state = model.snapshot?.thermalPressure else { return "Collecting…" }
        switch state {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        case .unknown: return "Unknown"
        }
    }

    private var powerSource: String {
        guard let source = model.snapshot?.powerSource else { return "Collecting…" }
        switch source {
        case .acAdapter: return "AC adapter"
        case .battery: return "Battery"
        case .unknown: return "Unknown"
        }
    }

    private func percent(_ value: Double?) -> String {
        guard let value else { return "Collecting…" }
        return value.formatted(.number.precision(.fractionLength(1))) + "%"
    }

    private func measurement(_ value: Double?, unit: String, decimals: Int = 2) -> String {
        guard let value else { return "Unavailable" }
        return value.formatted(.number.precision(.fractionLength(decimals))) + " " + unit
    }

    private func bytes(_ value: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(clamping: value), countStyle: .memory)
    }

    private func rate(_ value: Double?) -> String {
        guard let value else { return "Collecting…" }
        return ByteCountFormatter.string(fromByteCount: Int64(max(0, value)), countStyle: .decimal) + "/s"
    }
}

private struct MetricTile: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
        .padding(12)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
        .accessibilityHint(detail)
    }
}
