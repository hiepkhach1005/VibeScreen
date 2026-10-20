import VibeScreenCore
import AppKit
import Carbon
import SwiftUI

private enum NavigationItem: Hashable {
    case overview
    case devices
    case device(UUID)
    case monitor
    case settings

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .devices: return "Devices"
        case .device: return "TV"
        case .monitor: return "Monitor"
        case .settings: return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .overview: return "rectangle.3.group"
        case .devices: return "display.2"
        case .device: return "tv"
        case .monitor: return "gauge.with.dots.needle.67percent"
        case .settings: return "gearshape"
        }
    }
}

struct MainWindowView: View {
    @ObservedObject var container: AppContainer
    @State private var selection: NavigationItem? = .devices
    @State private var isDevicesExpanded = true

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Control") {
                    if container.nativeSettings.showOverviewInSidebar {
                        navigationRow(.overview)
                    }
                    DisclosureGroup(isExpanded: $isDevicesExpanded) {
                        ForEach(container.devices) { device in
                            Label(device.name, systemImage: "tv")
                            .tag(NavigationItem.device(device.id))
                            .help("Open controls and automation for \(device.name)")
                        }
                    } label: {
                        Label("Devices", systemImage: "display.2")
                    }
                    .tag(NavigationItem.devices)
                    if container.nativeSettings.showSystemMonitorInSidebar {
                        navigationRow(.monitor)
                    }
                }

                Section {
                    navigationRow(.settings)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("VibeScreen")
        } detail: {
            Group {
                switch selection ?? .overview {
                case .overview:
                    DashboardView(container: container)
                case .devices:
                    DevicesView(
                        container: container,
                        onSelectDevice: { selection = .device($0) }
                    )
                case let .device(deviceID):
                    if let device = container.devices.first(where: { $0.id == deviceID }) {
                        TVDeviceDetailView(
                            container: container,
                            device: device,
                            onDelete: { selection = .devices }
                        )
                        .id(device.id)
                    } else {
                        ContentUnavailableView(
                            "TV not found",
                            systemImage: "tv.slash",
                            description: Text("Select another TV from Devices.")
                        )
                    }
                case .monitor:
                    SystemMonitorView(container: container)
                case .settings:
                    SettingsView(container: container)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(VibeScreenTheme.canvas)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 920, minHeight: 600)
        .task {
            container.refreshDisplays()
            container.startPlatformEvents()
            if (selection == nil || selection == .devices),
               let firstDevice = container.devices.first {
                selection = .device(firstDevice.id)
            }
        }
        .onChange(of: container.devices.map(\.id)) { _, deviceIDs in
            if case let .device(selectedID) = selection,
               !deviceIDs.contains(selectedID) {
                selection = .devices
            }
            if !deviceIDs.isEmpty {
                isDevicesExpanded = true
                if selection == nil || selection == .devices {
                    selection = .device(deviceIDs[0])
                }
            }
        }
        .onChange(of: container.nativeSettings.showOverviewInSidebar) { _, isVisible in
            if !isVisible, selection == .overview {
                selection = .devices
            }
        }
        .onChange(of: container.nativeSettings.showSystemMonitorInSidebar) { _, isVisible in
            if !isVisible, selection == .monitor {
                selection = .devices
            }
        }
    }

    @ViewBuilder
    private func navigationRow(_ item: NavigationItem) -> some View {
        Label(item.title, systemImage: item.symbol)
            .tag(item)
    }
}

struct DashboardView: View {
    @ObservedObject var container: AppContainer

    private var quickPresets: [Preset] {
        container.presets.filter(\.showInQuickAccess)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HeaderView(
                    eyebrow: "NATIVE CONTROL CENTER",
                    title: "Your displays,\nin one calm place.",
                    subtitle: "A native macOS foundation for presets, automation, and TV control."
                )

                HStack(spacing: 14) {
                    StatusCard(
                        title: "Native shell",
                        value: "Running",
                        detail: "SwiftUI + menu bar",
                        symbol: "checkmark.seal.fill",
                        tint: VibeScreenTheme.mint
                    )
                    StatusCard(
                        title: "Connected devices",
                        value: "\(container.devices.count)",
                        detail: container.devices.isEmpty ? "No TVs configured" : "TV policies loaded",
                        symbol: "display.2",
                        tint: VibeScreenTheme.blue
                    )
                    StatusCard(
                        title: "Automation",
                        value: "Ready",
                        detail: "macOS power/session events connected",
                        symbol: "bolt.horizontal.circle.fill",
                        tint: VibeScreenTheme.amber
                    )
                }

                HStack(alignment: .top, spacing: 14) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeading(title: "Quick presets", subtitle: "Available from the menu bar")

                            if quickPresets.isEmpty {
                                EmptyStateView(
                                    symbol: "slider.horizontal.3",
                                    title: "No quick presets",
                                     message: "Mark a preset for quick access from the menu bar."
                                )
                            } else {
                                ForEach(quickPresets) { preset in
                                    PresetRow(preset: preset) {
                                        container.apply(preset)
                                    }
                                }
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeading(title: "Migration runway", subtitle: "What is being rebuilt")
                            MigrationStep(number: "01", title: "Native shell", detail: "Window and menu bar are in place.", state: .done)
                            MigrationStep(number: "02", title: "Core behavior", detail: "Preset parsing and execution are isolated.", state: .done)
                            MigrationStep(number: "03", title: "Mac services", detail: "Power, display, process, login, and WOL adapters are in place; Mac verification is next.", state: .next)
                             MigrationStep(number: "04", title: "TV protocols", detail: "LG pointer input and Samsung remote flow still need Mac hardware evidence.", state: .later)
                        }
                    }
                }

                Text(container.lastActionMessage)
                    .font(.footnote)
                    .foregroundStyle(VibeScreenTheme.secondaryText)
                    .padding(.horizontal, 4)

                Divider()

                PresetsView(container: container)

                Divider()

                GamesView(container: container)

                Divider()

                AutomationView()

                Divider()

                ActivityView(container: container)
            }
            .padding(32)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    container.refreshDisplays()
                    Task { await container.reload() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .help("Refresh the current state")
            }
        }
    }
}

struct PresetsView: View {
    @ObservedObject var container: AppContainer
    @State private var isShowingEditor = false
    @State private var editingPreset: Preset?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                SectionHeading(
                    title: "Presets",
                    subtitle: "Reusable display and TV actions, including menu bar quick access."
                )

                Spacer()

                Button {
                    editingPreset = nil
                    isShowingEditor = true
                } label: {
                    Label("New preset", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(VibeScreenTheme.blue)
            }

            if container.presets.isEmpty {
                GlassCard {
                    EmptyStateView(
                        symbol: "slider.horizontal.3",
                        title: "No presets",
                        message: "Create a preset to group repeatable display and TV actions."
                    )
                }
            } else {
                ForEach(container.presets) { preset in
                    GlassCard {
                        HStack(spacing: 16) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title2)
                                .foregroundStyle(VibeScreenTheme.blue)
                                .frame(width: 44, height: 44)
                                .background(VibeScreenTheme.blue.opacity(0.14), in: Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(preset.name)
                                    .font(.headline)
                                Text(preset.description)
                                    .font(.subheadline)
                                    .foregroundStyle(VibeScreenTheme.secondaryText)
                            }

                            Spacer()

                            if !preset.shortcut.isEmpty {
                                Text(preset.shortcut)
                                    .font(.system(.footnote, design: .monospaced))
                                    .foregroundStyle(VibeScreenTheme.secondaryText)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 6)
                                    .background(VibeScreenTheme.canvas.opacity(0.7), in: Capsule())
                            }

                            Button("Apply") {
                                container.apply(preset)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(VibeScreenTheme.blue)

                            Button {
                                editingPreset = preset
                                isShowingEditor = true
                            } label: {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(.borderless)
                            .help("Edit preset")

                            Button {
                                container.deletePreset(preset)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.red)
                            .help("Delete preset")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingEditor) {
            PresetEditorView(container: container, initial: editingPreset)
        }
    }
}

struct GamesView: View {
    @ObservedObject var container: AppContainer

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeading(
                title: "Games",
                subtitle: "Launch a macOS game together with its pre-launch and finalization workflow."
            )

            if container.gamePresets.isEmpty {
                GlassCard {
                    EmptyStateView(
                        symbol: "gamecontroller",
                        title: "No game presets",
                        message: "Migrated game presets will appear here. Windows executable paths stay unresolved until you choose a macOS app."
                    )
                }
            } else {
                ForEach(container.gamePresets) { preset in
                    GlassCard {
                        HStack(spacing: 14) {
                            Image(systemName: "gamecontroller")
                                .foregroundStyle(VibeScreenTheme.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(preset.name)
                                    .font(.headline)
                                Text(preset.launch?.pathOrBundleIdentifier ?? "No launch target")
                                    .font(.caption)
                                    .foregroundStyle(VibeScreenTheme.secondaryText)
                            }
                            Spacer()
                            Button("Launch") {
                                container.applyGame(preset)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(VibeScreenTheme.blue)
                        }
                    }
                }
            }
        }
    }
}

private struct PresetEditorView: View {
    @ObservedObject var container: AppContainer
    @Environment(\.dismiss) private var dismiss
    private let initial: Preset?
    @State private var name: String
    @State private var shortcut: String
    @State private var description: String
    @State private var stepsText: String
    @State private var quickAccess: Bool
    @State private var targetDeviceAddress: String

    init(container: AppContainer, initial: Preset?) {
        self.container = container
        self.initial = initial
        _name = State(initialValue: initial?.name ?? "")
        _shortcut = State(initialValue: initial?.shortcut ?? "")
        _description = State(initialValue: initial?.description ?? "")
        _stepsText = State(initialValue: initial?.steps.map(\.updatedRawValue).joined(separator: "\n") ?? "")
        _quickAccess = State(initialValue: initial?.showInQuickAccess ?? true)
        _targetDeviceAddress = State(initialValue: initial?.targetDeviceAddress ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(initial == nil ? "New preset" : "Edit preset")
                .font(.title2.weight(.semibold))

            Form {
                TextField("Name", text: $name)
                TextField("Shortcut", text: $shortcut)
                Toggle("Show in menu bar quick access", isOn: $quickAccess)
                Picker("Target TV", selection: $targetDeviceAddress) {
                    Text("All configured TVs").tag("")
                    ForEach(container.devices) { device in
                        Text("\(device.name) · \(device.host)").tag(device.host)
                    }
                }
                TextField("Description", text: $description, axis: .vertical)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Steps")
                        .font(.subheadline.weight(.semibold))
                    Text("One legacy-compatible step per line, for example Volume(20):100.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $stepsText)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 140)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.secondary.opacity(0.25))
                        }
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") { save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 560, height: 520)
    }

    private func save() {
        let stepLines = stepsText
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let preset = Preset(
            id: initial?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            shortcut: shortcut,
            triggers: initial?.triggers ?? [],
            steps: stepLines.map { PresetStepParser.parse($0) },
            description: description,
            showInQuickAccess: quickAccess,
            lastUsed: initial?.lastUsed,
            targetDeviceAddress: targetDeviceAddress.isEmpty ? nil : targetDeviceAddress,
            applicationIdentifier: initial?.applicationIdentifier,
            legacyNumericIdentifier: initial?.legacyNumericIdentifier
        )
        container.savePreset(preset)
        dismiss()
    }
}

struct DevicesView: View {
    @ObservedObject var container: AppContainer
    let onSelectDevice: (UUID) -> Void
    @State private var isShowingEditor = false
    @State private var editingDevice: TVDeviceDescriptor?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HeaderView(
                    eyebrow: "DEVICES",
                    title: "A clear view\nof every screen.",
                    subtitle: "Mac display snapshots and configured LG WebOS/Samsung Tizen devices live together here."
                )

                if container.displays.isEmpty {
                    GlassCard {
                        EmptyStateView(
                            symbol: "display.2",
                            title: "No displays detected",
                            message: "Display snapshots will appear when macOS reports an attached screen."
                        )
                    }
                } else {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeading(title: "Mac displays", subtitle: "Observed through AppKit/CoreGraphics")
                            ForEach(container.displays) { display in
                                DisplayRow(display: display)
                            }
                        }
                    }
                }

                if container.devices.isEmpty {
                    GlassCard {
                        EmptyStateView(
                            symbol: "tv",
                            title: "No TVs connected",
                            message: "Add and pair an LG WebOS or Samsung Tizen device. Automation settings become available on its device row."
                        )
                    }
                } else {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeading(title: "TV devices", subtitle: "Loaded from native Application Support")
                            ForEach(container.devices) { device in
                                TVDeviceRow(
                                    device: device,
                                    connectionState: container.deviceConnectionStates[device.id] ?? .disconnected,
                                    connectionMessage: container.deviceConnectionMessages[device.id],
                                    pendingCertificateFingerprint: container.pendingCertificateFingerprints[device.id],
                                    onCommand: { command in
                                        container.sendDeviceCommand(command, to: device)
                                    },
                                    onConnect: { container.connectDevice(device) },
                                    onTrustCertificate: { container.trustCertificateAndConnect(device) },
                                    onEdit: {
                                        editingDevice = device
                                        isShowingEditor = true
                                    },
                                    onOpen: { onSelectDevice(device.id) },
                                    onDelete: { container.deleteDevice(device) }
                                )
                            }
                        }
                    }
                }
            }
            .padding(32)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    editingDevice = nil
                    isShowingEditor = true
                } label: {
                    Label("Add TV", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingEditor) {
            TVDeviceEditorView(
                container: container,
                initial: editingDevice,
                onSave: onSelectDevice
            )
        }
    }
}

private struct DisplayRow: View {
    let display: MacDisplaySnapshot

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
                .foregroundStyle(VibeScreenTheme.blue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(display.name)
                    .font(.subheadline.weight(.semibold))
                Text("\(display.pixelWidth) × \(display.pixelHeight) · \(display.scaleFactor, specifier: "%.1f")× scale")
                    .font(.caption)
                    .foregroundStyle(VibeScreenTheme.secondaryText)
            }
            Spacer()
            Text(display.hdrState == nil ? "HDR unknown" : (display.hdrState == true ? "HDR" : "SDR"))
                .font(.caption.weight(.medium))
                .foregroundStyle(VibeScreenTheme.secondaryText)
        }
    }
}

private struct TVDeviceRow: View {
    let device: TVDeviceDescriptor
    let connectionState: TVConnectionState
    let connectionMessage: String?
    let pendingCertificateFingerprint: String?
    let onCommand: (String) -> Void
    let onConnect: () -> Void
    let onTrustCertificate: () -> Void
    let onEdit: () -> Void
    let onOpen: () -> Void
    let onDelete: () -> Void
    @State private var isShowingTrustConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "tv")
                    .foregroundStyle(connectionState == .connected ? .green : VibeScreenTheme.blue)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(device.name)
                        .font(.subheadline.weight(.semibold))
                    Text("\(device.kind == .lgWebOS ? "LG WebOS" : "Samsung Tizen") · \(device.host)")
                        .font(.caption)
                        .foregroundStyle(VibeScreenTheme.secondaryText)
                }
                Spacer()
                if connectionState == .connecting {
                    ProgressView()
                        .controlSize(.small)
                }
                Text(connectionLabel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(connectionColor)
                Button(connectionButtonLabel, action: onConnect)
                    .disabled(connectionState == .connecting)
                if pendingCertificateFingerprint != nil {
                    Button("Trust certificate & retry") {
                        isShowingTrustConfirmation = true
                    }
                }
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.borderless)
                .help("Edit TV connection")
                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
                .help("Delete TV")
            }

            if let connectionMessage, !connectionMessage.isEmpty {
                Text(connectionMessage)
                    .font(.caption)
                    .foregroundStyle(connectionState == .failed || connectionState == .pairingRequired ? .orange : VibeScreenTheme.secondaryText)
                    .textSelection(.enabled)
            }

            HStack(spacing: 12) {
                TVRemoteControls(device: device, onCommand: onCommand)
                Spacer()
                Text(device.powerPolicy.triggersEnabled ? "Automation on" : "Automation off")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(VibeScreenTheme.secondaryText)
                Button("Open", action: onOpen)
                    .buttonStyle(.borderedProminent)
                    .help("Open controls and automation for \(device.name)")
            }
        }
        .alert("Trust this TV certificate?", isPresented: $isShowingTrustConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Trust & Pair", action: onTrustCertificate)
        } message: {
            Text("Only continue if this certificate appeared while connecting to your LG TV. The app will pin this exact SHA-256 fingerprint for this device:\n\n\(pendingCertificateFingerprint ?? "Unavailable")")
        }
    }

    private var connectionLabel: String {
        switch connectionState {
        case .disconnected: return "Not tested"
        case .connecting: return "Connecting"
        case .connected: return "Paired"
        case .pairingRequired: return "Needs approval"
        case .failed: return "Connection failed"
        }
    }

    private var connectionButtonLabel: String {
        switch connectionState {
        case .connected: return "Test again"
        case .pairingRequired: return "Approve pairing"
        case .disconnected, .failed: return "Reconnect"
        case .connecting: return "Connecting"
        }
    }

    private var connectionColor: Color {
        switch connectionState {
        case .connected: return .green
        case .pairingRequired, .failed: return .orange
        case .disconnected, .connecting: return VibeScreenTheme.secondaryText
        }
    }
}

private struct TVDeviceDetailView: View {
    @ObservedObject var container: AppContainer
    let device: TVDeviceDescriptor
    let onDelete: () -> Void

    @State private var isShowingConnectionEditor = false
    @State private var isShowingTrustConfirmation = false
    @State private var isConfirmingDelete = false

    private var connectionState: TVConnectionState {
        container.deviceConnectionStates[device.id] ?? .disconnected
    }

    private var connectionMessage: String? {
        container.deviceConnectionMessages[device.id]
    }

    private var pendingCertificateFingerprint: String? {
        container.pendingCertificateFingerprints[device.id]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HeaderView(
                    eyebrow: device.kind == .lgWebOS ? "LG WEBOS TV" : "SAMSUNG TIZEN TV",
                    title: device.name,
                    subtitle: "Connection, remote controls, and device-specific automation in one place."
                )

                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 12) {
                            Image(systemName: "tv")
                                .font(.title2)
                                .foregroundStyle(connectionState == .connected ? .green : VibeScreenTheme.blue)
                                .frame(width: 40, height: 40)
                                .background(VibeScreenTheme.blue.opacity(0.12), in: Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(device.kind == .lgWebOS ? "LG WebOS" : "Samsung Tizen") · \(device.host)")
                                    .font(.headline)
                                Text(connectionLabel)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(connectionColor)
                            }

                            Spacer()

                            if connectionState == .connecting {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Button(connectionButtonLabel) {
                                container.connectDevice(device)
                            }
                            .disabled(connectionState == .connecting)

                            if pendingCertificateFingerprint != nil {
                                Button("Trust certificate & retry") {
                                    isShowingTrustConfirmation = true
                                }
                            }

                            Button {
                                isShowingConnectionEditor = true
                            } label: {
                                Label("Edit connection", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                isConfirmingDelete = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }

                        if let connectionMessage, !connectionMessage.isEmpty {
                            Text(connectionMessage)
                                .font(.caption)
                                .foregroundStyle(
                                    connectionState == .failed || connectionState == .pairingRequired
                                        ? .orange
                                        : VibeScreenTheme.secondaryText
                                )
                                .textSelection(.enabled)
                        }

                        Divider()

                        TVRemoteControls(
                            device: device,
                            onCommand: { container.sendDeviceCommand($0, to: device) }
                        )
                    }
                }

                if device.kind == .lgWebOS {
                    LGDeviceControlsView(
                        device: device,
                        liveSyncEnabled: container.nativeSettings.lgLiveSyncEnabled,
                        liveSyncIntervalSeconds: container.nativeSettings.lgLiveSyncIntervalSeconds,
                        onControl: { control, value in
                            await container.applyLGControl(control, value: value, to: device)
                        },
                        onCommand: { command, label in
                            await container.applyTypedDeviceCommand(command, label: label, to: device)
                        },
                        onRefresh: {
                            await container.loadLGControlValues(for: device)
                        },
                        onLiveRefresh: {
                            await container.loadLGLiveValues(for: device)
                        }
                    )
                }

                TVPowerPolicyView(
                    device: device,
                    onSave: { container.updatePowerPolicy($0, for: device) }
                )

                Text(container.lastActionMessage)
                    .font(.footnote)
                    .foregroundStyle(VibeScreenTheme.secondaryText)
                    .padding(.horizontal, 4)
            }
            .padding(32)
        }
        .sheet(isPresented: $isShowingConnectionEditor) {
            TVDeviceEditorView(container: container, initial: device)
        }
        .alert("Trust this TV certificate?", isPresented: $isShowingTrustConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Trust & Pair") {
                container.trustCertificateAndConnect(device)
            }
        } message: {
            Text("Only continue if this certificate appeared while connecting to your LG TV. The app will pin this exact SHA-256 fingerprint for this device:\n\n\(pendingCertificateFingerprint ?? "Unavailable")")
        }
        .confirmationDialog(
            "Delete \(device.name)?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete TV", role: .destructive) {
                onDelete()
                container.deleteDevice(device)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the device configuration and its active pairing credential.")
        }
    }

    private var connectionLabel: String {
        switch connectionState {
        case .disconnected: return "Not tested"
        case .connecting: return "Connecting"
        case .connected: return "Paired"
        case .pairingRequired: return "Needs approval"
        case .failed: return "Connection failed"
        }
    }

    private var connectionButtonLabel: String {
        switch connectionState {
        case .connected: return "Test again"
        case .pairingRequired: return "Approve pairing"
        case .disconnected, .failed: return "Reconnect"
        case .connecting: return "Connecting"
        }
    }

    private var connectionColor: Color {
        switch connectionState {
        case .connected: return .green
        case .pairingRequired, .failed: return .orange
        case .disconnected, .connecting: return VibeScreenTheme.secondaryText
        }
    }
}

private struct LGDeviceControlsView: View {
    let device: TVDeviceDescriptor
    let liveSyncEnabled: Bool
    let liveSyncIntervalSeconds: Int
    let onControl: (LGControlDescriptor, String) async -> Bool
    let onCommand: (TVCommand, String) async -> Bool
    let onRefresh: () async -> LGControlSnapshot
    let onLiveRefresh: () async -> [String: String]
    @State private var values: [String: String] = Dictionary(
        uniqueKeysWithValues: LGControlCatalog.controls.map { ($0.id, $0.defaultValue) }
    )
    @State private var applicationID = ""
    @State private var webAddress = ""
    @State private var applications: [LGNamedResource] = []
    @State private var inputs: [LGNamedResource] = []
    @State private var selectedApplicationID = ""
    @State private var selectedInputID = ""
    @State private var hdmiIconPort = 1
    @State private var hdmiIcon = "pc"
    @State private var pendingAdvancedAction: LGAdvancedAction?
    @State private var isRefreshing = false
    @State private var isApplyingControl = false
    @State private var isAdjustingControl = false
    @State private var isSynchronizing = false
    @State private var lastLiveSync: Date?
    @State private var isQuickActionsExpanded = false
    @State private var isGameAndHDMIExpanded = false
    @State private var isAdvancedExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("LG controls")
                        .font(.title2.weight(.semibold))
                    Text(device.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isRefreshing || isApplyingControl {
                    ProgressView()
                        .controlSize(.small)
                }
                if let lastLiveSync {
                    Label("Synced", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .help("Last synchronized at \(lastLiveSync.formatted(date: .omitted, time: .standard))")
                }
                Button {
                    Task { await refreshValues() }
                } label: {
                    Label("Read from TV", systemImage: "arrow.clockwise")
                }
                .disabled(isRefreshing || isApplyingControl)
            }

            Divider()

            controlSection(
                title: "Game Bar",
                subtitle: "The four default live controls and TV volume.",
                controls: gameBarControls,
                expanded: true
            )

            quickActions

            ForEach(LGControlGroup.allCases.filter { $0 != .gameBar }, id: \.self) { group in
                let controls = LGControlCatalog.controls(in: group).filter { $0.id != "audioVolume" }
                if group == .gameAndHDMI {
                    collapsibleControlSection(
                        title: group.rawValue,
                        subtitle: subtitle(for: group),
                        controls: controls,
                        isExpanded: $isGameAndHDMIExpanded
                    )
                } else {
                    controlSection(
                        title: group.rawValue,
                        subtitle: subtitle(for: group),
                        controls: controls,
                        expanded: false
                    )
                }
            }

            advancedActions
        }
        .disabled(isRefreshing || isApplyingControl || isSynchronizing)
        .confirmationDialog(
            pendingAdvancedAction?.title ?? "Apply advanced LG action?",
            isPresented: Binding(
                get: { pendingAdvancedAction != nil },
                set: { if !$0 { pendingAdvancedAction = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Apply", role: .destructive) {
                if let action = pendingAdvancedAction {
                    applyCommand(action.command, label: action.title)
                }
                pendingAdvancedAction = nil
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(pendingAdvancedAction?.warning ?? "This action changes advanced TV state.")
        }
        .task {
            await refreshValues()
        }
        .task(id: liveSyncTaskID) {
            guard liveSyncEnabled else { return }
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(liveSyncIntervalSeconds))
                } catch {
                    return
                }
                await refreshLiveValues()
            }
        }
    }

    private var liveSyncTaskID: String {
        "\(liveSyncEnabled)-\(liveSyncIntervalSeconds)"
    }

    private var gameBarControls: [LGControlDescriptor] {
        var controls = LGControlCatalog.controls(in: .gameBar)
        if let volumeControl = LGControlCatalog.controls.first(where: { $0.id == "audioVolume" }) {
            controls.append(volumeControl)
        }
        return controls
    }

    private var quickActions: some View {
        collapsibleSection(
            title: "Remote, media, inputs, and apps",
            subtitle: "Playback, channel, input, application, and URL actions.",
            isExpanded: $isQuickActionsExpanded
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    actionButton("Play", "play.fill", .mediaPlay)
                    actionButton("Pause", "pause.fill", .mediaPause)
                    actionButton("Stop", "stop.fill", .mediaStop)
                    actionButton("Channel up", "chevron.up", .channelUp)
                    actionButton("Channel down", "chevron.down", .channelDown)
                    Spacer()
                }
                if inputs.isEmpty {
                    HStack {
                        ForEach(1...4, id: \.self) { port in
                            Button("HDMI \(port)") {
                                applyCommand(.setInput("HDMI_\(port)"), label: "Switch to HDMI \(port)")
                            }
                        }
                        Spacer()
                    }
                } else {
                    HStack {
                        Picker("Input", selection: $selectedInputID) {
                            ForEach(inputs) { input in
                                Text(input.title).tag(input.id)
                            }
                        }
                        Button("Switch input") {
                            applyCommand(.setInput(selectedInputID), label: "Switch input")
                        }
                        .disabled(selectedInputID.isEmpty)
                    }
                }
                if applications.isEmpty {
                    HStack {
                        TextField("LG application ID", text: $applicationID)
                        Button("Launch app") {
                            applyCommand(
                                .launchApplication(identifier: applicationID, parameters: nil),
                                label: "Launch app"
                            )
                        }
                        .disabled(applicationID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } else {
                    HStack {
                        Picker("Application", selection: $selectedApplicationID) {
                            ForEach(applications) { application in
                                Text(application.title).tag(application.id)
                            }
                        }
                        Button("Launch") {
                            applyCommand(
                                .launchApplication(identifier: selectedApplicationID, parameters: nil),
                                label: "Launch app"
                            )
                        }
                        .disabled(selectedApplicationID.isEmpty)
                        Button("Close") {
                            applyCommand(.closeApplication(selectedApplicationID), label: "Close app")
                        }
                        .disabled(selectedApplicationID.isEmpty)
                    }
                }
                HStack {
                    TextField("https://…", text: $webAddress)
                    Button("Open URL") {
                        applyCommand(.openURL(webAddress), label: "Open URL")
                    }
                    .disabled(URL(string: webAddress)?.scheme == nil)
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var advancedActions: some View {
        collapsibleSection(
            title: "Advanced",
            subtitle: "Service, panel, and HDMI icon controls.",
            isExpanded: $isAdvancedExpanded
        ) {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Service and panel controls")
                        .font(.subheadline.weight(.medium))
                    Text("Every action below requires confirmation because availability and side effects vary by model and firmware.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    advancedButton(.reboot)
                    Menu("TPC") {
                        advancedButton(.tpcEnabled)
                        advancedButton(.tpcDisabled)
                    }
                    Menu("GSR") {
                        advancedButton(.gsrEnabled)
                        advancedButton(.gsrDisabled)
                    }
                    Menu("Service menu") {
                        advancedButton(.serviceMenuEnabled)
                        advancedButton(.serviceMenuDisabled)
                        Divider()
                        advancedButton(.inStart)
                        advancedButton(.ezAdjust)
                    }
                    advancedButton(.softwareUpdate)
                    Spacer()
                }
                Divider()
                HStack {
                    Picker("HDMI icon port", selection: $hdmiIconPort) {
                        ForEach(1...4, id: \.self) { port in
                            Text("HDMI \(port)").tag(port)
                        }
                    }
                    Picker("Icon", selection: $hdmiIcon) {
                        ForEach(Self.hdmiIcons, id: \.id) { option in
                            Text(option.title).tag(option.id)
                        }
                    }
                    Button("Apply HDMI icon") {
                        let title = Self.hdmiIcons.first { $0.id == hdmiIcon }?.title ?? "HDMI"
                        applyCommand(
                            .setLGHDMIIcon(port: hdmiIconPort, icon: hdmiIcon, label: title),
                            label: "Set HDMI \(hdmiIconPort) icon"
                        )
                    }
                    Spacer()
                }
            }
            .padding(.vertical, 6)
        }
    }

    private func collapsibleControlSection(
        title: String,
        subtitle: String,
        controls: [LGControlDescriptor],
        isExpanded: Binding<Bool>
    ) -> some View {
        collapsibleSection(title: title, subtitle: subtitle, isExpanded: isExpanded) {
            VStack(spacing: 0) {
                ForEach(controls) { control in
                    LGControlRow(
                        control: control,
                        value: valueBinding(for: control),
                        onApply: { applyControl(control) },
                        onEditingChanged: { isAdjustingControl = $0 }
                    )
                    if control.id != controls.last?.id { Divider() }
                }
            }
        }
    }

    private func collapsibleSection<Content: View>(
        title: String,
        subtitle: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        DisclosureGroup(isExpanded: isExpanded) {
            content()
                .padding(.top, 8)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
    }

    private static let hdmiIcons: [LGControlOption] = [
        LGControlOption("hdmigeneric", title: "HDMI"),
        LGControlOption("satellite", title: "Satellite"),
        LGControlOption("settopbox", title: "Set-Top Box"),
        LGControlOption("dvd", title: "DVD Player"),
        LGControlOption("bluray", title: "Blu-ray Player"),
        LGControlOption("hometheater", title: "Home Theater"),
        LGControlOption("gameconsole", title: "Game Console"),
        LGControlOption("streamingbox", title: "Streaming Box"),
        LGControlOption("camera", title: "Camera"),
        LGControlOption("pc", title: "PC"),
        LGControlOption("mobile", title: "Mobile Device")
    ]

    private func advancedButton(_ action: LGAdvancedAction) -> some View {
        Button(action.menuTitle) {
            pendingAdvancedAction = action
        }
    }

    @ViewBuilder
    private func controlSection(
        title: String,
        subtitle: String,
        controls: [LGControlDescriptor],
        expanded: Bool
    ) -> some View {
        if expanded {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.headline)
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                ForEach(controls) { control in
                    LGControlRow(
                        control: control,
                        value: valueBinding(for: control),
                        onApply: { applyControl(control) },
                        onEditingChanged: { isAdjustingControl = $0 }
                    )
                    if control.id != controls.last?.id { Divider() }
                }
            }
            .padding(14)
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
        } else {
            DisclosureGroup {
                VStack(spacing: 0) {
                    ForEach(controls) { control in
                        LGControlRow(
                            control: control,
                            value: valueBinding(for: control),
                            onApply: { applyControl(control) },
                            onEditingChanged: { isAdjustingControl = $0 }
                        )
                        if control.id != controls.last?.id { Divider() }
                    }
                }
                .padding(.top, 8)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func valueBinding(for control: LGControlDescriptor) -> Binding<String> {
        Binding(
            get: { values[control.id] ?? control.defaultValue },
            set: { values[control.id] = $0 }
        )
    }

    private func refreshValues() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        let snapshot = await onRefresh()
        values.merge(snapshot.values) { _, current in current }
        applications = snapshot.applications
        inputs = snapshot.inputs
        if selectedApplicationID.isEmpty {
            selectedApplicationID = applications.first?.id ?? ""
        }
        if selectedInputID.isEmpty {
            selectedInputID = inputs.first?.id ?? ""
        }
        isRefreshing = false
        lastLiveSync = Date()
    }

    private func refreshLiveValues() async {
        guard !isRefreshing, !isApplyingControl, !isAdjustingControl else { return }
        isSynchronizing = true
        defer { isSynchronizing = false }
        let currentValues = await onLiveRefresh()
        guard !currentValues.isEmpty else { return }
        values.merge(currentValues) { _, current in current }
        lastLiveSync = Date()
    }

    private func applyControl(_ control: LGControlDescriptor) {
        guard !isApplyingControl, !isSynchronizing else { return }
        isApplyingControl = true
        let value = values[control.id] ?? control.defaultValue
        Task {
            let succeeded = await onControl(control, value)
            if succeeded {
                await refreshLiveValuesAfterApply()
            }
            isApplyingControl = false
        }
    }

    private func refreshLiveValuesAfterApply() async {
        let currentValues = await onLiveRefresh()
        if !currentValues.isEmpty {
            values.merge(currentValues) { _, current in current }
            lastLiveSync = Date()
        }
    }

    private func actionButton(_ title: String, _ symbol: String, _ command: TVCommand) -> some View {
        Button {
            applyCommand(command, label: title)
        } label: {
            Label(title, systemImage: symbol)
        }
    }

    private func applyCommand(_ command: TVCommand, label: String) {
        guard !isApplyingControl, !isSynchronizing else { return }
        isApplyingControl = true
        Task {
            _ = await onCommand(command, label)
            isApplyingControl = false
        }
    }

    private func subtitle(for group: LGControlGroup) -> String {
        switch group {
        case .gameBar: return ""
        case .gameAndHDMI: return "Game Optimizer, VRR, ALLM, PC mode, and per-port HDMI controls."
        case .picture: return "Picture modes, brightness processing, color, HDR, and noise reduction."
        case .aiPicture: return "AI picture options supported by newer TV generations."
        case .aspectRatio: return "Aspect ratio, scan, zoom, position, and scale."
        case .motion: return "TruMotion, OLED Motion Pro, and Real Cinema."
        case .sound: return "Volume, sound mode, output, and processing."
        case .oledCare: return "Panel protection and network wake options."
        case .whiteBalance: return "Expert white-balance offsets, gains, and method."
        }
    }
}

private enum LGAdvancedAction: String, Identifiable {
    case reboot
    case tpcEnabled
    case tpcDisabled
    case gsrEnabled
    case gsrDisabled
    case serviceMenuEnabled
    case serviceMenuDisabled
    case inStart
    case ezAdjust
    case softwareUpdate

    var id: String { rawValue }

    var menuTitle: String {
        switch self {
        case .reboot: return "Reboot…"
        case .tpcEnabled: return "Enable TPC…"
        case .tpcDisabled: return "Disable TPC…"
        case .gsrEnabled: return "Enable GSR…"
        case .gsrDisabled: return "Disable GSR…"
        case .serviceMenuEnabled: return "Enable full menu…"
        case .serviceMenuDisabled: return "Disable full menu…"
        case .inStart: return "Open InStart…"
        case .ezAdjust: return "Open EzAdjust…"
        case .softwareUpdate: return "Software Update…"
        }
    }

    var title: String {
        switch self {
        case .reboot: return "Reboot TV"
        case .tpcEnabled: return "Enable TPC"
        case .tpcDisabled: return "Disable TPC"
        case .gsrEnabled: return "Enable GSR"
        case .gsrDisabled: return "Disable GSR"
        case .serviceMenuEnabled: return "Enable full service menu"
        case .serviceMenuDisabled: return "Disable full service menu"
        case .inStart: return "Open InStart"
        case .ezAdjust: return "Open EzAdjust"
        case .softwareUpdate: return "Open Software Update"
        }
    }

    var warning: String {
        switch self {
        case .reboot:
            return "The TV will immediately stop playback and restart."
        case .tpcEnabled, .tpcDisabled, .gsrEnabled, .gsrDisabled:
            return "This writes an OLED panel-protection service setting. It is intended for supported 2020+ OLED models; misuse may increase panel wear."
        case .serviceMenuEnabled, .serviceMenuDisabled, .inStart, .ezAdjust:
            return "Service menus can change protected factory settings. Continue only if you understand your exact TV model and firmware."
        case .softwareUpdate:
            return "This opens the TV software-update application. The app will not confirm or install an update for you."
        }
    }

    var command: TVCommand {
        switch self {
        case .reboot:
            return .reboot
        case .tpcEnabled:
            return .setLGOLEDProtection(name: "TPC", enabled: true)
        case .tpcDisabled:
            return .setLGOLEDProtection(name: "TPC", enabled: false)
        case .gsrEnabled:
            return .setLGOLEDProtection(name: "GSR", enabled: true)
        case .gsrDisabled:
            return .setLGOLEDProtection(name: "GSR", enabled: false)
        case .serviceMenuEnabled:
            return .setLGSystemSetting(category: "other", name: "svcMenuFlag", value: .bool(true))
        case .serviceMenuDisabled:
            return .setLGSystemSetting(category: "other", name: "svcMenuFlag", value: .bool(false))
        case .inStart:
            return .launchApplication(
                identifier: "com.webos.app.factorywin",
                parameters: .object(["id": .string("executeFactory"), "irKey": .string("inStart")])
            )
        case .ezAdjust:
            return .launchApplication(
                identifier: "com.webos.app.factorywin",
                parameters: .object(["id": .string("executeFactory"), "irKey": .string("ezAdjust")])
            )
        case .softwareUpdate:
            return .launchApplication(
                identifier: "com.webos.app.softwareupdate",
                parameters: .object(["mode": .string("user"), "flagUpdate": .bool(true)])
            )
        }
    }
}

private struct LGControlRow: View {
    private static let labelWidth: CGFloat = 240

    let control: LGControlDescriptor
    @Binding var value: String
    let onApply: () -> Void
    let onEditingChanged: (Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(control.title)
                    .font(.subheadline)
                if let year = control.minimumModelYear {
                    Text("LG \(year)+")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: Self.labelWidth, alignment: .leading)
            editor
            if showsApplyButton {
                Button("Apply", action: onApply)
                    .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var editor: some View {
        switch control.valueKind {
        case let .range(minimum, maximum):
            HStack(spacing: 8) {
                Slider(
                    value: sliderBinding(defaultValue: minimum),
                    in: Double(minimum)...Double(maximum),
                    onEditingChanged: { editing in
                        onEditingChanged(editing)
                        if !editing { onApply() }
                    }
                )
                .frame(minWidth: 240, maxWidth: .infinity)
                .accessibilityLabel(control.title)
                .accessibilityValue(displayedValue)
                rangeValueLabel(minimum: minimum, maximum: maximum)
            }
            .frame(maxWidth: .infinity)
        case let .options(options):
            Picker(control.title, selection: $value) {
                ForEach(options) { option in
                    Text(option.title).tag(option.id)
                }
            }
            .labelsHidden()
            .frame(width: 210)
        case let .integerArray(count, minimum, maximum):
            VStack(alignment: .trailing, spacing: 2) {
                TextField("Comma-separated values", text: $value)
                    .frame(width: 330)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.caption, design: .monospaced))
                    .onSubmit(onApply)
                Text("\(count) values · \(minimum)…\(maximum)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var showsApplyButton: Bool {
        if case .range = control.valueKind { return false }
        return true
    }

    private var displayedValue: String {
        guard case let .range(minimum, maximum) = control.valueKind else { return value }
        let suffix = minimum == 0 && maximum == 100 ? "%" : ""
        return "\(Int(value) ?? minimum)\(suffix)"
    }

    @ViewBuilder
    private func rangeValueLabel(minimum: Int, maximum: Int) -> some View {
        if minimum == 0 && maximum == 100 {
            Text(displayedValue)
                .font(.body.monospacedDigit())
                .frame(width: 54, alignment: .trailing)
                .contentShape(Rectangle())
                .overlay {
                    MouseButtonClickOverlay(
                        onLeftClick: { adjustPercentage(by: 5, minimum: minimum, maximum: maximum) },
                        onRightClick: { adjustPercentage(by: -5, minimum: minimum, maximum: maximum) }
                    )
                }
                .help("Left-click to increase by 5%; right-click to decrease by 5%")
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Left-click increases by 5 percent; right-click decreases by 5 percent")
        } else {
            Text(displayedValue)
                .font(.body.monospacedDigit())
                .frame(width: 54, alignment: .trailing)
        }
    }

    private func adjustPercentage(by delta: Int, minimum: Int, maximum: Int) {
        let current = Int(value) ?? minimum
        let adjusted = min(maximum, max(minimum, current + delta))
        guard adjusted != current else { return }
        onEditingChanged(true)
        value = String(adjusted)
        onEditingChanged(false)
        onApply()
    }

    private func sliderBinding(defaultValue: Int) -> Binding<Double> {
        Binding(
            get: { Double(Int(value) ?? defaultValue) },
            set: { value = String(Int($0.rounded())) }
        )
    }
}

private struct TVRemoteControls: View {
    let device: TVDeviceDescriptor
    let onCommand: (String) -> Void

    private var keyPrefix: String {
        device.kind == .lgWebOS ? "" : "KEY_"
    }

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                remoteButton("Power on", "PowerOn", "power.circle", help: "Turn the TV on")
                remoteButton("Power off", "PowerOff", "power", help: "Turn the TV off")
            }

            Divider()
                .frame(height: 28)

            HStack(spacing: 6) {
                remoteButton("Volume down", "VolumeDown", "speaker.minus", help: "Lower the TV volume")
                remoteButton("Volume up", "VolumeUp", "speaker.plus", help: "Raise the TV volume")
                remoteButton("Mute", "Mute(true)", "speaker.slash", help: "Mute the TV audio")
            }

            Divider()
                .frame(height: 28)

            HStack(spacing: 6) {
                remoteButton("Left", "\(keyPrefix)LEFT", "chevron.left", help: "Navigate left")
                remoteButton("OK", "\(keyPrefix)ENTER", "checkmark", help: "Confirm the selected item")
                remoteButton("Right", "\(keyPrefix)RIGHT", "chevron.right", help: "Navigate right")
                remoteButton("Home", "\(keyPrefix)HOME", "house", help: "Open the TV Home screen")
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func remoteButton(
        _ title: String,
        _ command: String,
        _ symbol: String,
        help: String
    ) -> some View {
        Button {
            onCommand(command)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .medium))
                .frame(width: 24, height: 22)
                .accessibilityLabel(title)
                .accessibilityHint(help)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .help(help)
    }
}

private struct TVDeviceEditorView: View {
    @ObservedObject var container: AppContainer
    @Environment(\.dismiss) private var dismiss
    private let initial: TVDeviceDescriptor?
    private let onSave: (UUID) -> Void
    @State private var name: String
    @State private var host: String
    @State private var macAddress: String
    @State private var kind: TVDeviceKind
    @State private var secureConnection: Bool

    init(
        container: AppContainer,
        initial: TVDeviceDescriptor?,
        onSave: @escaping (UUID) -> Void = { _ in }
    ) {
        self.container = container
        self.initial = initial
        self.onSave = onSave
        _name = State(initialValue: initial?.name ?? "")
        _host = State(initialValue: initial?.host ?? "")
        _macAddress = State(initialValue: initial?.macAddress ?? "")
        _kind = State(initialValue: initial?.kind ?? .lgWebOS)
        _secureConnection = State(initialValue: initial?.usesSecureConnection ?? true)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(initial == nil ? "Add TV device" : "Edit TV device")
                .font(.title2.weight(.semibold))

            Form {
                Section("Connection") {
                    TextField("Name", text: $name)
                    Picker("Platform", selection: $kind) {
                        Text("LG WebOS").tag(TVDeviceKind.lgWebOS)
                        Text("Samsung Tizen").tag(TVDeviceKind.samsungTizen)
                    }
                    TextField("IP address or host", text: $host)
                    TextField("MAC address for Wake-on-LAN", text: $macAddress)
                    Toggle("Use secure connection", isOn: $secureConnection)
                    if kind == .lgWebOS && secureConnection {
                        Text("LG secure WebSocket uses port 3001 and may present a local certificate that macOS does not trust. If pairing fails, turn this off to try ws:// on port 3000.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollIndicators(.hidden)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save & Pair") { save() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 600, height: 390)
    }

    private func save() {
        let deviceID = initial?.id ?? UUID()
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedMAC = macAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let device = TVDeviceDescriptor(
            id: deviceID,
            name: normalizedName,
            kind: kind,
            host: normalizedHost,
            macAddress: normalizedMAC.isEmpty ? nil : normalizedMAC,
            usesSecureConnection: secureConnection,
            credentialReference: initial?.credentialReference ?? "tv-credential-\(deviceID.uuidString.lowercased())",
            trustedCertificateSHA256: secureConnection && initial?.host.caseInsensitiveCompare(normalizedHost) == .orderedSame
                ? initial?.trustedCertificateSHA256
                : nil,
            powerPolicy: initial?.powerPolicy ?? TVPowerPolicy()
        )
        container.saveDevice(device)
        onSave(deviceID)
        dismiss()
    }
}

private struct TVPowerPolicyView: View {
    let device: TVDeviceDescriptor
    let onSave: (TVPowerPolicy) -> Void

    @State private var triggersEnabled: Bool
    @State private var powerOnAfterStartup: Bool
    @State private var powerOnAfterResume: Bool
    @State private var powerOnAfterManualPowerOff: Bool
    @State private var powerOffOnShutdown: Bool
    @State private var turnScreenOffOnShutdown: Bool
    @State private var turnScreenOnAfterStartup: Bool
    @State private var powerOffOnStandby: Bool
    @State private var powerOffOnScreenSaver: Bool
    @State private var powerOnAfterScreenSaver: Bool
    @State private var powerOffAfterSessionLock: Bool
    @State private var powerOnAfterSessionUnlock: Bool
    @State private var turnScreenOffOnScreenSaver: Bool
    @State private var turnScreenOnAfterScreenSaver: Bool
    @State private var screenSaverMinimumDuration: String

    init(device: TVDeviceDescriptor, onSave: @escaping (TVPowerPolicy) -> Void) {
        self.device = device
        self.onSave = onSave
        let policy = device.powerPolicy
        _triggersEnabled = State(initialValue: policy.triggersEnabled)
        _powerOnAfterStartup = State(initialValue: policy.powerOnAfterStartup)
        _powerOnAfterResume = State(initialValue: policy.powerOnAfterResume)
        _powerOnAfterManualPowerOff = State(initialValue: policy.powerOnAfterManualPowerOff)
        _powerOffOnShutdown = State(initialValue: policy.powerOffOnShutdown)
        _turnScreenOffOnShutdown = State(initialValue: policy.turnScreenOffOnShutdown)
        _turnScreenOnAfterStartup = State(initialValue: policy.turnScreenOnAfterStartup)
        _powerOffOnStandby = State(initialValue: policy.powerOffOnStandby)
        _powerOffOnScreenSaver = State(initialValue: policy.powerOffOnScreenSaver)
        _powerOnAfterScreenSaver = State(initialValue: policy.powerOnAfterScreenSaver)
        _powerOffAfterSessionLock = State(initialValue: policy.powerOffAfterSessionLock)
        _powerOnAfterSessionUnlock = State(initialValue: policy.powerOnAfterSessionUnlock)
        _turnScreenOffOnScreenSaver = State(initialValue: policy.turnScreenOffOnScreenSaver)
        _turnScreenOnAfterScreenSaver = State(initialValue: policy.turnScreenOnAfterScreenSaver)
        _screenSaverMinimumDuration = State(initialValue: String(policy.screenSaverMinimumDuration))
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeading(
                    title: "Power and session automation",
                    subtitle: "These triggers apply only to \(device.name)."
                )

                GroupBox {
                    Toggle("Enable automation for this TV", isOn: $triggersEnabled)
                        .help("Enable or disable all power and session triggers for \(device.name)")
                }

                GroupBox("macOS startup and shutdown") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Turn screen on after macOS startup", isOn: $turnScreenOnAfterStartup)
                            .help("Send a screen-on command to this TV when VibeScreen starts with macOS.")
                        Toggle("Turn screen off on macOS shutdown", isOn: $turnScreenOffOnShutdown)
                            .help("Send a screen-off command to this TV when macOS begins shutting down.")
                        Text("These options control the TV screen only. They do not replace the full TV power options below unless enabled.")
                            .font(.caption)
                            .foregroundStyle(VibeScreenTheme.secondaryText)
                    }
                    .disabled(!triggersEnabled)
                    .padding(.vertical, 4)
                }

                GroupBox("Power and session events") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Power on after startup", isOn: $powerOnAfterStartup)
                        Toggle("Power on after resume", isOn: $powerOnAfterResume)
                        Toggle("Power on after a manual TV power-off", isOn: $powerOnAfterManualPowerOff)
                            .help("Allow macOS wake events to turn the TV back on after you used the remote or shortcut to turn it off.")
                        Toggle("Power off on shutdown", isOn: $powerOffOnShutdown)
                        Toggle("Power off on Mac sleep", isOn: $powerOffOnStandby)
                        Toggle("Power off after session lock", isOn: $powerOffAfterSessionLock)
                        Toggle("Power on after session unlock", isOn: $powerOnAfterSessionUnlock)
                    }
                    .disabled(!triggersEnabled)
                    .padding(.vertical, 4)
                }

                GroupBox("Screen sleep and wake") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Power off when screens sleep", isOn: $powerOffOnScreenSaver)
                        Toggle("Power on when screens wake", isOn: $powerOnAfterScreenSaver)
                        Toggle("Turn screen off instead of powering off", isOn: $turnScreenOffOnScreenSaver)
                        Toggle("Turn screen on after screens wake", isOn: $turnScreenOnAfterScreenSaver)
                        TextField("Screen sleep delay (seconds)", text: $screenSaverMinimumDuration)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityHint("Enter zero or a positive whole number")

                        if !isDelayValid {
                            Text("Enter a whole number of seconds greater than or equal to zero.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .disabled(!triggersEnabled)
                    .padding(.vertical, 4)
                }

                HStack {
                    Spacer()
                    Button("Save automation") { save() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!isDelayValid || !isDirty)
                }
            }
        }
    }

    private var parsedDelay: Int? {
        Int(screenSaverMinimumDuration.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var isDelayValid: Bool {
        guard let parsedDelay else { return false }
        return parsedDelay >= 0
    }

    private var currentPolicy: TVPowerPolicy? {
        guard let parsedDelay, parsedDelay >= 0 else { return nil }
        return TVPowerPolicy(
            powerOnAfterStartup: powerOnAfterStartup,
            powerOnAfterResume: powerOnAfterResume,
            powerOffOnShutdown: powerOffOnShutdown,
            turnScreenOffOnShutdown: turnScreenOffOnShutdown,
            turnScreenOnAfterStartup: turnScreenOnAfterStartup,
            powerOffOnStandby: powerOffOnStandby,
            powerOffOnScreenSaver: powerOffOnScreenSaver,
            powerOnAfterScreenSaver: powerOnAfterScreenSaver,
            powerOnAfterManualPowerOff: powerOnAfterManualPowerOff,
            powerOffAfterSessionLock: powerOffAfterSessionLock,
            powerOnAfterSessionUnlock: powerOnAfterSessionUnlock,
            turnScreenOffOnScreenSaver: turnScreenOffOnScreenSaver,
            turnScreenOnAfterScreenSaver: turnScreenOnAfterScreenSaver,
            screenSaverMinimumDuration: parsedDelay,
            triggersEnabled: triggersEnabled
        )
    }

    private var isDirty: Bool {
        currentPolicy != device.powerPolicy
    }

    private func save() {
        guard let currentPolicy else { return }
        onSave(currentPolicy)
    }
}

struct AutomationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeading(
                title: "Automation",
                subtitle: "Startup, resume, display, process, and screensaver events."
            )

            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeading(title: "Event sources", subtitle: "Mapped from the legacy dispatcher layer")
                    AutomationRow(symbol: "power", title: "Power and session", detail: "Startup, resume, standby, lock, and unlock")
                    AutomationRow(symbol: "rectangle.3.group", title: "Display changes", detail: "Connected screens and HDR state")
                    AutomationRow(symbol: "app.badge", title: "Process activity", detail: "Launch, exit, foreground, and fullscreen")
                    AutomationRow(symbol: "moon.zzz", title: "Screensaver", detail: "Start and stop events")
                }
            }
        }
    }
}

struct ActivityView: View {
    @ObservedObject var container: AppContainer

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeading(
                title: "Activity",
                subtitle: "Latest result from the current app session."
            )

            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(title: "Latest result", subtitle: "Current native shell session")
                    Label(
                        resultTitle,
                        systemImage: resultSymbol
                    )
                    .font(.headline)
                    .foregroundStyle(resultTint)
                    Text(container.lastActionMessage)
                        .font(.subheadline)
                        .foregroundStyle(VibeScreenTheme.secondaryText)
                }
            }
        }
    }

    private var resultTitle: String {
        switch container.lastExecutionStatus {
        case .succeeded: return "Last preset completed"
        case .failed: return "Last preset needs attention"
        case .cancelled: return "Last preset was cancelled"
        case nil: return "No preset has run yet"
        }
    }

    private var resultSymbol: String {
        switch container.lastExecutionStatus {
        case .succeeded: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .cancelled: return "pause.circle.fill"
        case nil: return "clock"
        }
    }

    private var resultTint: Color {
        switch container.lastExecutionStatus {
        case .succeeded: return VibeScreenTheme.mint
        case .failed: return VibeScreenTheme.amber
        case .cancelled, nil: return VibeScreenTheme.secondaryText
        }
    }
}

struct SettingsView: View {
    @ObservedObject var container: AppContainer
    @State private var launchAtLogin = false
    @State private var loginItemMessage = ""
    @State private var shortcutError = ""
    private let loginItemManager = LoginItemManager()
    private let systemMonitorSamplingOptions = [500, 1_000, 2_000, 5_000, 10_000, 30_000, 60_000]

    var body: some View {
        Form {
            Section("Application") {
                Toggle(
                    "Show Overview in sidebar",
                    isOn: Binding(
                        get: { container.nativeSettings.showOverviewInSidebar },
                        set: { container.setShowOverviewInSidebar($0) }
                    )
                )
                .help("Show or hide the combined Overview workspace in the sidebar")
                Toggle(
                    "Show Monitor in sidebar",
                    isOn: Binding(
                        get: { container.nativeSettings.showSystemMonitorInSidebar },
                        set: { container.setSystemMonitorVisibleInSidebar($0) }
                    )
                )
                .help("Show or hide the Monitor destination. Hiding it stops all Monitor sampling immediately.")
                Toggle("Launch at login (menu bar only)", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            try loginItemManager.setEnabled(newValue)
                            refreshLoginItemState(persist: true)
                        } catch {
                            launchAtLogin = loginItemManager.isRegistered
                            loginItemMessage = error.localizedDescription
                        }
                    }
                    .accessibilityHint("Start VibeScreen in the menu bar after you sign in to this Mac")
                if !loginItemMessage.isEmpty {
                    HStack(alignment: .firstTextBaseline) {
                        Text(loginItemMessage)
                            .font(.caption)
                            .foregroundStyle(
                                loginItemManager.state == .requiresApproval ? Color.orange : Color.secondary
                            )
                        if loginItemManager.state == .requiresApproval {
                            Spacer()
                            Button("Open Login Items") {
                                loginItemManager.openSystemSettings()
                            }
                        }
                    }
                }
            }

            Section("TV keyboard shortcuts") {
                LabeledContent("First TV power toggle") {
                    ShortcutRecorderControl(
                        shortcut: container.nativeSettings.tvPowerToggleShortcut,
                        accessibilityLabel: "Change the shortcut that toggles power for the first TV"
                    ) { shortcut in
                        let error = container.updateTVPowerToggleShortcut(shortcut)
                        shortcutError = error ?? ""
                        return error
                    }
                }
                if !shortcutError.isEmpty {
                    Label(shortcutError, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                Label(
                    container.globalTVShortcutStatus,
                    systemImage: container.globalTVShortcutStatus == "Active"
                        ? "keyboard.badge.ellipsis"
                        : "exclamationmark.triangle.fill"
                )
                    .font(.caption)
                    .foregroundStyle(container.globalTVShortcutStatus == "Active" ? Color.secondary : Color.orange)
                Text("Choose Change, then press one shortcut containing Command, Option, or Control. When the first TV is on, it powers off; when it is off, it powers on. Press Escape to cancel. If the TV stops answering after standby, the app only attempts the safe PowerOn/Wake-on-LAN path and never guesses PowerOff.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("LG live sync") {
                Toggle(
                    "Automatically read live values from LG TVs",
                    isOn: Binding(
                        get: { container.nativeSettings.lgLiveSyncEnabled },
                        set: { container.setLGLiveSyncEnabled($0) }
                    )
                )

                LabeledContent("Refresh interval") {
                    Stepper(
                        value: Binding(
                            get: { container.nativeSettings.lgLiveSyncIntervalSeconds },
                            set: { container.setLGLiveSyncIntervalSeconds($0) }
                        ),
                        in: NativeAppSettings.minimumLGLiveSyncIntervalSeconds ... NativeAppSettings.maximumLGLiveSyncIntervalSeconds
                    ) {
                        Text("\(container.nativeSettings.lgLiveSyncIntervalSeconds) seconds")
                            .monospacedDigit()
                    }
                    .disabled(!container.nativeSettings.lgLiveSyncEnabled)
                    .accessibilityHint("Choose how often the app reads Game Bar values and volume from the TV")
                }
            }

            Section("System Monitor") {
                LabeledContent("Sampling interval") {
                    Picker(
                        "Sampling interval",
                        selection: Binding(
                            get: { selectedSystemMonitorSamplingMilliseconds },
                            set: { container.setSystemMonitorIntervalMilliseconds($0) }
                        )
                    ) {
                        ForEach(systemMonitorSamplingOptions, id: \.self) { milliseconds in
                            Text(systemMonitorIntervalLabel(for: milliseconds))
                                .tag(milliseconds)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .accessibilityHint("Choose how often Monitor collects CPU, memory, network, thermal, and power data")
                }
                Text("Sampling runs only while Monitor is open. Shorter intervals use more CPU and energy.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Credential storage") {
                switch container.credentialStorageMode {
                case .keychain:
                    Label("TV credentials are stored in Keychain.", systemImage: "checkmark.shield.fill")
                        .foregroundStyle(.secondary)
                case .developmentFile:
                    Label("Development-only file storage is enabled.", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("TV keys are stored as owner-only files in Application Support. This is less secure than Keychain; do not copy, sync, or commit them.")
                        .foregroundStyle(.secondary)
                    Text("Build without VIBESCREEN_DEVELOPMENT_FILE_CREDENTIALS to move credentials back to Keychain and delete the files on the next connection.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding(24)
        .navigationTitle("Settings")
        .task {
            refreshLoginItemState(persist: false)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshLoginItemState(persist: true)
        }
    }

    private func refreshLoginItemState(persist: Bool) {
        launchAtLogin = loginItemManager.isRegistered
        switch loginItemManager.state {
        case .disabled:
            loginItemMessage = "Launch at login is off."
        case .enabled:
            loginItemMessage = "VibeScreen will start in the menu bar without opening its window."
        case .requiresApproval:
            loginItemMessage = "Allow VibeScreen in System Settings > General > Login Items to finish enabling this setting."
        case .unavailable:
            loginItemMessage = "Launch at login is unavailable for this app build."
        }
        if persist, container.nativeSettings.launchAtLogin != launchAtLogin {
            container.setLaunchAtLogin(launchAtLogin)
        }
    }

    private var selectedSystemMonitorSamplingMilliseconds: Int {
        let current = container.nativeSettings.systemMonitorIntervalMilliseconds
        return systemMonitorSamplingOptions.min {
            abs($0 - current) < abs($1 - current)
        } ?? 1_000
    }

    private func systemMonitorIntervalLabel(for milliseconds: Int) -> String {
        let seconds = Double(milliseconds) / 1_000
        return seconds.formatted(.number.precision(.fractionLength(seconds == seconds.rounded() ? 0 : 1)))
            + " seconds"
    }

}

private struct ShortcutRecorderControl: NSViewRepresentable {
    let shortcut: GlobalKeyboardShortcut
    let accessibilityLabel: String
    let onChange: @MainActor (GlobalKeyboardShortcut) -> String?

    func makeNSView(context: Context) -> ShortcutCaptureButton {
        let button = ShortcutCaptureButton()
        button.bezelStyle = .rounded
        button.setButtonType(.momentaryPushIn)
        button.shortcut = shortcut
        button.capture = onChange
        button.setAccessibilityLabel(accessibilityLabel)
        button.refreshTitle()
        return button
    }

    func updateNSView(_ button: ShortcutCaptureButton, context: Context) {
        button.shortcut = shortcut
        button.capture = onChange
        button.setAccessibilityLabel(accessibilityLabel)
        if !button.isRecording {
            button.refreshTitle()
        }
    }
}

@MainActor
private final class ShortcutCaptureButton: NSButton {
    var shortcut = GlobalKeyboardShortcut.defaultTVPowerToggle
    var capture: (@MainActor (GlobalKeyboardShortcut) -> String?)?
    private(set) var isRecording = false

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        beginRecording()
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            if event.keyCode == UInt16(kVK_Return) || event.keyCode == UInt16(kVK_Space) {
                beginRecording()
            } else {
                super.keyDown(with: event)
            }
            return
        }

        guard !event.isARepeat else { return }
        if event.keyCode == UInt16(kVK_Escape) {
            finishRecording()
            return
        }

        do {
            let candidate = try GlobalKeyboardShortcut(recording: event)
            if let error = capture?(candidate) {
                toolTip = error
                NSSound.beep()
            } else {
                shortcut = candidate
                toolTip = nil
            }
        } catch {
            toolTip = error.localizedDescription
            NSSound.beep()
        }
        finishRecording()
    }

    func refreshTitle() {
        title = "\(shortcut.displayText)  Change…"
        setAccessibilityValue(shortcut.displayText)
        sizeToFit()
    }

    private func beginRecording() {
        isRecording = true
        title = "Press shortcut…"
        toolTip = "Press Escape to cancel"
        window?.makeFirstResponder(self)
        sizeToFit()
    }

    private func finishRecording() {
        isRecording = false
        refreshTitle()
    }
}

private struct HeaderView: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow)
                .font(.caption.weight(.semibold))
                .tracking(1.5)
                .foregroundStyle(VibeScreenTheme.blue)
            Text(title)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(VibeScreenTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(VibeScreenTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct StatusCard: View {
    let title: String
    let value: String
    let detail: String
    let symbol: String
    let tint: Color

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(VibeScreenTheme.secondaryText)
                    Spacer()
                    Image(systemName: symbol)
                        .foregroundStyle(tint)
                }
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(VibeScreenTheme.secondaryText)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SectionHeading: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(VibeScreenTheme.secondaryText)
        }
    }
}

private struct PresetRow: View {
    let preset: Preset
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.lefthalf.filled")
                .foregroundStyle(VibeScreenTheme.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text(preset.name)
                    .font(.subheadline.weight(.semibold))
                Text("\(preset.steps.count) step\(preset.steps.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(VibeScreenTheme.secondaryText)
            }
            Spacer()
            Button("Apply", action: action)
                .buttonStyle(.borderless)
                .foregroundStyle(VibeScreenTheme.blue)
        }
        .padding(.vertical, 3)
    }
}

private struct MigrationStep: View {
    enum State {
        case done
        case next
        case later
    }

    let number: String
    let title: String
    let detail: String
    let state: State

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(.caption, design: .monospaced).weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(VibeScreenTheme.secondaryText)
            }
        }
    }

    private var tint: Color {
        switch state {
        case .done: return VibeScreenTheme.mint
        case .next: return VibeScreenTheme.blue
        case .later: return VibeScreenTheme.secondaryText
        }
    }
}

private struct AutomationRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(VibeScreenTheme.blue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(VibeScreenTheme.secondaryText)
            }
            Spacer()
             Text("Mapped")
                .font(.caption.weight(.medium))
                .foregroundStyle(VibeScreenTheme.secondaryText)
        }
    }
}

private struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 30))
                .foregroundStyle(VibeScreenTheme.blue)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(VibeScreenTheme.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 460)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .accessibilityElement(children: .combine)
    }
}

private struct GlassCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .modifier(GlassCardSurface())
    }
}

private struct GlassCardSurface: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect(.regular, in: .rect(cornerRadius: 22))
        } else {
            content
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
        }
    }
}

private enum VibeScreenTheme {
    static let canvas = Color(nsColor: .windowBackgroundColor)
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let blue = Color(red: 0.22, green: 0.48, blue: 0.98)
    static let mint = Color(red: 0.18, green: 0.72, blue: 0.57)
    static let amber = Color(red: 0.93, green: 0.57, blue: 0.18)
}
