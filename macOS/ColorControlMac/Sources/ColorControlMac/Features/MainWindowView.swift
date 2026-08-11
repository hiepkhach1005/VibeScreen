import ColorControlCore
import AppKit
import SwiftUI

private enum NavigationItem: String, CaseIterable, Hashable, Identifiable {
    case overview
    case devices
    case presets
    case games
    case automation
    case activity
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .devices: return "Devices"
        case .presets: return "Presets"
        case .games: return "Games"
        case .automation: return "Automation"
        case .activity: return "Activity"
        case .settings: return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .overview: return "rectangle.3.group"
        case .devices: return "display.2"
        case .presets: return "slider.horizontal.3"
        case .games: return "gamecontroller"
        case .automation: return "bolt.horizontal.circle"
        case .activity: return "waveform.path.ecg"
        case .settings: return "gearshape"
        }
    }
}

struct MainWindowView: View {
    @ObservedObject var container: AppContainer
    @State private var selection: NavigationItem? = .overview

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Control") {
                    navigationRow(.overview)
                    navigationRow(.devices)
                    navigationRow(.presets)
                    navigationRow(.games)
                }

                Section("Observe") {
                    navigationRow(.automation)
                    navigationRow(.activity)
                }

                Section {
                    navigationRow(.settings)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("ColorControl")
        } detail: {
            Group {
                switch selection ?? .overview {
                case .overview:
                    DashboardView(container: container)
                case .devices:
                    DevicesView(container: container)
                case .presets:
                    PresetsView(container: container)
                case .games:
                    GamesView(container: container)
                case .automation:
                    AutomationView()
                case .activity:
                    ActivityView(container: container)
                case .settings:
                    SettingsView(container: container)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ColorControlTheme.canvas)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 920, minHeight: 600)
        .task {
            container.refreshDisplays()
            await container.reload()
            container.startPlatformEvents()
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
                        tint: ColorControlTheme.mint
                    )
                    StatusCard(
                        title: "Connected devices",
                        value: "\(container.devices.count)",
                        detail: container.devices.isEmpty ? "No TVs configured" : "TV policies loaded",
                        symbol: "display.2",
                        tint: ColorControlTheme.blue
                    )
                    StatusCard(
                        title: "Automation",
                        value: "Ready",
                        detail: "macOS power/session events connected",
                        symbol: "bolt.horizontal.circle.fill",
                        tint: ColorControlTheme.amber
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
                    .foregroundStyle(ColorControlTheme.secondaryText)
                    .padding(.horizontal, 4)
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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HeaderView(
                    eyebrow: "PRESETS",
                    title: "Small changes,\nreliably repeatable.",
                    subtitle: "Legacy-compatible steps are routed to typed native adapters with visible failures."
                )

                ForEach(container.presets) { preset in
                    GlassCard {
                        HStack(spacing: 16) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title2)
                                .foregroundStyle(ColorControlTheme.blue)
                                .frame(width: 44, height: 44)
                                .background(ColorControlTheme.blue.opacity(0.14), in: Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(preset.name)
                                    .font(.headline)
                                Text(preset.description)
                                    .font(.subheadline)
                                    .foregroundStyle(ColorControlTheme.secondaryText)
                            }

                            Spacer()

                            if !preset.shortcut.isEmpty {
                                Text(preset.shortcut)
                                    .font(.system(.footnote, design: .monospaced))
                                    .foregroundStyle(ColorControlTheme.secondaryText)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 6)
                                    .background(ColorControlTheme.canvas.opacity(0.7), in: Capsule())
                            }

                            Button("Apply") {
                                container.apply(preset)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(ColorControlTheme.blue)

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
            .padding(32)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    editingPreset = nil
                    isShowingEditor = true
                } label: {
                    Label("New preset", systemImage: "plus")
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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HeaderView(
                    eyebrow: "GAMES",
                    title: "Launch the right setup.\nThen let it finish cleanly.",
                    subtitle: "Native .app, bundle-identifier, pre-launch, post-launch, and finalization workflows replace the Windows launcher."
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
                                    .foregroundStyle(ColorControlTheme.blue)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(preset.name)
                                        .font(.headline)
                                    Text(preset.launch?.pathOrBundleIdentifier ?? "No launch target")
                                        .font(.caption)
                                        .foregroundStyle(ColorControlTheme.secondaryText)
                                }
                                Spacer()
                                Button("Launch") {
                                    container.applyGame(preset)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(ColorControlTheme.blue)
                            }
                        }
                    }
                }
            }
            .padding(32)
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
                            message: "Add an LG WebOS or Samsung Tizen device to configure power policy and pairing."
                        )
                    }
                } else {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeading(title: "TV devices", subtitle: "Loaded from native Application Support")
                            ForEach(container.devices) { device in
                                TVDeviceRow(
                                    device: device,
                                    onCommand: { command in
                                        container.sendDeviceCommand(command, to: device)
                                    },
                                    onEdit: {
                                        editingDevice = device
                                        isShowingEditor = true
                                    },
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
            TVDeviceEditorView(container: container, initial: editingDevice)
        }
    }
}

private struct DisplayRow: View {
    let display: MacDisplaySnapshot

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
                .foregroundStyle(ColorControlTheme.blue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(display.name)
                    .font(.subheadline.weight(.semibold))
                Text("\(display.pixelWidth) × \(display.pixelHeight) · \(display.scaleFactor, specifier: "%.1f")× scale")
                    .font(.caption)
                    .foregroundStyle(ColorControlTheme.secondaryText)
            }
            Spacer()
            Text(display.hdrState == nil ? "HDR unknown" : (display.hdrState == true ? "HDR" : "SDR"))
                .font(.caption.weight(.medium))
                .foregroundStyle(ColorControlTheme.secondaryText)
        }
    }
}

private struct TVDeviceRow: View {
    let device: TVDeviceDescriptor
    let onCommand: (String) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "tv")
                .foregroundStyle(ColorControlTheme.blue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(device.name)
                    .font(.subheadline.weight(.semibold))
                Text("\(device.kind == .lgWebOS ? "LG WebOS" : "Samsung Tizen") · \(device.host)")
                    .font(.caption)
                    .foregroundStyle(ColorControlTheme.secondaryText)
            }
            Spacer()
            Text(device.powerPolicy.triggersEnabled ? "Automation on" : "Automation off")
                .font(.caption.weight(.medium))
                .foregroundStyle(ColorControlTheme.secondaryText)
            TVRemoteControls(device: device, onCommand: onCommand)
            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .help("Edit TV")
            Button(action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.red)
            .help("Delete TV")
        }
    }
}

private struct TVRemoteControls: View {
    let device: TVDeviceDescriptor
    let onCommand: (String) -> Void

    private var keyPrefix: String {
        device.kind == .lgWebOS ? "" : "KEY_"
    }

    var body: some View {
        HStack(spacing: 4) {
            remoteButton("Power on", "PowerOn", "power.circle")
            remoteButton("Power off", "PowerOff", "power")
            remoteButton("Vol −", "VolumeDown", "minus.volume")
            remoteButton("Vol +", "VolumeUp", "plus.volume")
            remoteButton("Mute", "Mute(true)", "speaker.slash")
            remoteButton("◀", "\(keyPrefix)LEFT", "chevron.left")
            remoteButton("OK", "\(keyPrefix)ENTER", "checkmark")
            remoteButton("▶", "\(keyPrefix)RIGHT", "chevron.right")
            remoteButton("Home", "\(keyPrefix)HOME", "house")
        }
        .accessibilityElement(children: .contain)
    }

    private func remoteButton(_ title: String, _ command: String, _ symbol: String) -> some View {
        Button {
            onCommand(command)
        } label: {
            Image(systemName: symbol)
                .accessibilityLabel(title)
        }
        .buttonStyle(.borderless)
        .help(title)
    }
}

private struct TVDeviceEditorView: View {
    @ObservedObject var container: AppContainer
    @Environment(\.dismiss) private var dismiss
    private let initial: TVDeviceDescriptor?
    @State private var name: String
    @State private var host: String
    @State private var macAddress: String
    @State private var kind: TVDeviceKind
    @State private var secureConnection: Bool
    @State private var triggersEnabled: Bool
    @State private var powerOnAfterStartup: Bool
    @State private var powerOnAfterResume: Bool
    @State private var powerOnAfterManualPowerOff: Bool
    @State private var powerOffOnShutdown: Bool
    @State private var powerOffOnStandby: Bool
    @State private var powerOffOnScreenSaver: Bool
    @State private var powerOnAfterScreenSaver: Bool
    @State private var powerOffAfterSessionLock: Bool
    @State private var powerOnAfterSessionUnlock: Bool
    @State private var turnScreenOffOnScreenSaver: Bool
    @State private var turnScreenOnAfterScreenSaver: Bool
    @State private var screenSaverMinimumDuration: String

    init(container: AppContainer, initial: TVDeviceDescriptor?) {
        self.container = container
        self.initial = initial
        let policy = initial?.powerPolicy ?? TVPowerPolicy()
        _name = State(initialValue: initial?.name ?? "")
        _host = State(initialValue: initial?.host ?? "")
        _macAddress = State(initialValue: initial?.macAddress ?? "")
        _kind = State(initialValue: initial?.kind ?? .lgWebOS)
        _secureConnection = State(initialValue: initial?.usesSecureConnection ?? true)
        _triggersEnabled = State(initialValue: policy.triggersEnabled)
        _powerOnAfterStartup = State(initialValue: policy.powerOnAfterStartup)
        _powerOnAfterResume = State(initialValue: policy.powerOnAfterResume)
        _powerOnAfterManualPowerOff = State(initialValue: policy.powerOnAfterManualPowerOff)
        _powerOffOnShutdown = State(initialValue: policy.powerOffOnShutdown)
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
                }

                Section("Power and session automation") {
                    Toggle("Enable device triggers", isOn: $triggersEnabled)
                    Toggle("Power on after startup", isOn: $powerOnAfterStartup)
                    Toggle("Power on after resume", isOn: $powerOnAfterResume)
                    Toggle("Power on after a manual TV power-off", isOn: $powerOnAfterManualPowerOff)
                    Toggle("Power off on shutdown", isOn: $powerOffOnShutdown)
                    Toggle("Power off on Mac sleep", isOn: $powerOffOnStandby)
                    Toggle("Power off when screens sleep", isOn: $powerOffOnScreenSaver)
                    Toggle("Power on when screens wake", isOn: $powerOnAfterScreenSaver)
                    Toggle("Power off after session lock", isOn: $powerOffAfterSessionLock)
                    Toggle("Power on after session unlock", isOn: $powerOnAfterSessionUnlock)
                    Toggle("Turn screen off instead of powering off", isOn: $turnScreenOffOnScreenSaver)
                    Toggle("Turn screen on after screens wake", isOn: $turnScreenOnAfterScreenSaver)
                    TextField("Screen sleep delay (seconds)", text: $screenSaverMinimumDuration)
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") { save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 600, height: 680)
    }

    private func save() {
        let deviceID = initial?.id ?? UUID()
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedMAC = macAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let policy = TVPowerPolicy(
            powerOnAfterStartup: powerOnAfterStartup,
            powerOnAfterResume: powerOnAfterResume,
            powerOffOnShutdown: powerOffOnShutdown,
            powerOffOnStandby: powerOffOnStandby,
            powerOffOnScreenSaver: powerOffOnScreenSaver,
            powerOnAfterScreenSaver: powerOnAfterScreenSaver,
            powerOnAfterManualPowerOff: powerOnAfterManualPowerOff,
            powerOffAfterSessionLock: powerOffAfterSessionLock,
            powerOnAfterSessionUnlock: powerOnAfterSessionUnlock,
            turnScreenOffOnScreenSaver: turnScreenOffOnScreenSaver,
            turnScreenOnAfterScreenSaver: turnScreenOnAfterScreenSaver,
            screenSaverMinimumDuration: Int(screenSaverMinimumDuration) ?? 0,
            triggersEnabled: triggersEnabled
        )
        let device = TVDeviceDescriptor(
            id: deviceID,
            name: normalizedName,
            kind: kind,
            host: normalizedHost,
            macAddress: normalizedMAC.isEmpty ? nil : normalizedMAC,
            usesSecureConnection: secureConnection,
            credentialReference: initial?.credentialReference ?? "tv-credential-\(deviceID.uuidString.lowercased())",
            powerPolicy: policy
        )
        container.saveDevice(device)
        dismiss()
    }
}

struct AutomationView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HeaderView(
                    eyebrow: "AUTOMATION",
                    title: "Let context\ndo the quiet work.",
                    subtitle: "Startup, resume, display, process, and screensaver events map to typed macOS adapters."
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
            .padding(32)
        }
    }
}

struct ActivityView: View {
    @ObservedObject var container: AppContainer

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HeaderView(
                    eyebrow: "ACTIVITY",
                    title: "A readable trail\nof what happened.",
                    subtitle: "The current result is shown here; persistent OSLog-backed history is the next diagnostics slice."
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
                            .foregroundStyle(ColorControlTheme.secondaryText)
                    }
                }
            }
            .padding(32)
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
        case .succeeded: return ColorControlTheme.mint
        case .failed: return ColorControlTheme.amber
        case .cancelled, nil: return ColorControlTheme.secondaryText
        }
    }
}

struct SettingsView: View {
    @ObservedObject var container: AppContainer
    @State private var launchAtLogin = false
    @State private var loginItemMessage = ""
    private let loginItemManager = LoginItemManager()

    var body: some View {
        Form {
            Section("Native application") {
                LabeledContent("Runtime", value: "SwiftUI / macOS")
                    LabeledContent("Data migration", value: "Native snapshot + dry-run importers")
                LabeledContent("Legacy source", value: "Read-only")
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            try loginItemManager.setEnabled(newValue)
                            container.setLaunchAtLogin(newValue)
                            loginItemMessage = newValue ? "Launch at login enabled" : "Launch at login disabled"
                        } catch {
                            launchAtLogin = loginItemManager.isEnabled
                            loginItemMessage = error.localizedDescription
                        }
                    }
                if !loginItemMessage.isEmpty {
                    Text(loginItemMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Safety") {
                Text("Device, power, display, and Keychain permissions will be requested only when the corresponding feature is enabled.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Reload shell state") {
                    Task { await container.reload() }
                }
            }
        }
        .formStyle(.grouped)
        .padding(24)
        .navigationTitle("Settings")
        .task {
            launchAtLogin = loginItemManager.isEnabled
        }
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
                .foregroundStyle(ColorControlTheme.blue)
            Text(title)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(ColorControlTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(ColorControlTheme.secondaryText)
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
                        .foregroundStyle(ColorControlTheme.secondaryText)
                    Spacer()
                    Image(systemName: symbol)
                        .foregroundStyle(tint)
                }
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(ColorControlTheme.secondaryText)
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
                .foregroundStyle(ColorControlTheme.secondaryText)
        }
    }
}

private struct PresetRow: View {
    let preset: Preset
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.lefthalf.filled")
                .foregroundStyle(ColorControlTheme.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text(preset.name)
                    .font(.subheadline.weight(.semibold))
                Text("\(preset.steps.count) step\(preset.steps.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(ColorControlTheme.secondaryText)
            }
            Spacer()
            Button("Apply", action: action)
                .buttonStyle(.borderless)
                .foregroundStyle(ColorControlTheme.blue)
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
                    .foregroundStyle(ColorControlTheme.secondaryText)
            }
        }
    }

    private var tint: Color {
        switch state {
        case .done: return ColorControlTheme.mint
        case .next: return ColorControlTheme.blue
        case .later: return ColorControlTheme.secondaryText
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
                .foregroundStyle(ColorControlTheme.blue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(ColorControlTheme.secondaryText)
            }
            Spacer()
             Text("Mapped")
                .font(.caption.weight(.medium))
                .foregroundStyle(ColorControlTheme.secondaryText)
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
                .foregroundStyle(ColorControlTheme.blue)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(ColorControlTheme.secondaryText)
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

private enum ColorControlTheme {
    static let canvas = Color(nsColor: .windowBackgroundColor)
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let blue = Color(red: 0.22, green: 0.48, blue: 0.98)
    static let mint = Color(red: 0.18, green: 0.72, blue: 0.57)
    static let amber = Color(red: 0.93, green: 0.57, blue: 0.18)
}
