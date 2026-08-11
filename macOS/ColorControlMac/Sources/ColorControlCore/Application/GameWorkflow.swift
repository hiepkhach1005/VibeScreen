import Foundation

public enum GameProcessAutoAction: String, Codable, Sendable, Equatable {
    case none
    case suspend
    case restart
}

public struct GameLaunchSpecification: Codable, Sendable, Equatable {
    public let pathOrBundleIdentifier: String
    public let arguments: [String]
    public let workingDirectory: String?

    public init(
        pathOrBundleIdentifier: String,
        arguments: [String] = [],
        workingDirectory: String? = nil
    ) {
        self.pathOrBundleIdentifier = pathOrBundleIdentifier
        self.arguments = arguments
        self.workingDirectory = workingDirectory
    }
}

public struct LaunchedProcess: Codable, Sendable, Equatable {
    public let identifier: Int32?

    public init(identifier: Int32? = nil) {
        self.identifier = identifier
    }
}

public struct GamePreset: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public var name: String
    public var launch: GameLaunchSpecification?
    public var preLaunchSteps: [PresetStep]
    public var postLaunchSteps: [PresetStep]
    public var finalizeSteps: [PresetStep]
    public var autoApply: Bool
    public var processAutoAction: GameProcessAutoAction
    public var showInQuickAccess: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        launch: GameLaunchSpecification? = nil,
        preLaunchSteps: [PresetStep] = [],
        postLaunchSteps: [PresetStep] = [],
        finalizeSteps: [PresetStep] = [],
        autoApply: Bool = false,
        processAutoAction: GameProcessAutoAction = .none,
        showInQuickAccess: Bool = false
    ) {
        self.id = id
        self.name = name
        self.launch = launch
        self.preLaunchSteps = preLaunchSteps
        self.postLaunchSteps = postLaunchSteps
        self.finalizeSteps = finalizeSteps
        self.autoApply = autoApply
        self.processAutoAction = processAutoAction
        self.showInQuickAccess = showInQuickAccess
    }
}

public protocol GameProcessLauncher: Sendable {
    func launch(_ specification: GameLaunchSpecification) async throws -> LaunchedProcess
    func waitForExit(_ process: LaunchedProcess) async throws
}

public extension GameProcessLauncher {
    func waitForExit(_ process: LaunchedProcess) async throws {
        _ = process
    }
}

public enum GameWorkflowStatus: String, Codable, Sendable, Equatable {
    case succeeded
    case failed
    case cancelled
}

public struct GameWorkflowResult: Codable, Sendable, Equatable {
    public let presetID: UUID
    public let status: GameWorkflowStatus
    public let process: LaunchedProcess?
    public let phaseResults: [PresetExecutionResult]

    public init(
        presetID: UUID,
        status: GameWorkflowStatus,
        process: LaunchedProcess?,
        phaseResults: [PresetExecutionResult]
    ) {
        self.presetID = presetID
        self.status = status
        self.process = process
        self.phaseResults = phaseResults
    }
}

/// Keeps the legacy pre/post/finalize workflow while intentionally dropping
/// Windows-only elevation, affinity, and priority operations from the native
/// contract.
public actor GameWorkflowCoordinator {
    private let processLauncher: any GameProcessLauncher
    private let stepExecutor: PresetExecutionCoordinator

    public init(
        processLauncher: any GameProcessLauncher,
        actionExecutor: any PresetActionExecutor,
        clock: any PresetClock = SystemPresetClock()
    ) {
        self.processLauncher = processLauncher
        self.stepExecutor = PresetExecutionCoordinator(actionExecutor: actionExecutor, clock: clock)
    }

    public func execute(
        _ preset: GamePreset,
        policy: PresetExecutionPolicy = PresetExecutionPolicy()
    ) async -> GameWorkflowResult {
        var phases: [PresetExecutionResult] = []

        let pre = await executePhase(presetID: preset.id, name: preset.name, steps: preset.preLaunchSteps, policy: policy)
        phases.append(pre)
        guard pre.status == .succeeded else {
            return GameWorkflowResult(
                presetID: preset.id,
                status: pre.status == .cancelled ? .cancelled : .failed,
                process: nil,
                phaseResults: phases
            )
        }

        var process: LaunchedProcess?
        if let launch = preset.launch {
            do {
                process = try await processLauncher.launch(launch)
            } catch {
                let failure = PresetExecutionResult(
                    presetID: preset.id,
                    status: .failed,
                    steps: [
                        PresetStepResult(
                            id: UUID(),
                            action: .legacy(name: "launch", value: launch.pathOrBundleIdentifier),
                            succeeded: false,
                            failure: PresetStepFailure(message: error.localizedDescription)
                        )
                    ]
                )
                phases.append(failure)
                return GameWorkflowResult(presetID: preset.id, status: .failed, process: nil, phaseResults: phases)
            }
        }

        let post = await executePhase(presetID: preset.id, name: preset.name, steps: preset.postLaunchSteps, policy: policy)
        phases.append(post)
        guard post.status == .succeeded else {
            return GameWorkflowResult(
                presetID: preset.id,
                status: post.status == .cancelled ? .cancelled : .failed,
                process: process,
                phaseResults: phases
            )
        }

        if let process, !preset.finalizeSteps.isEmpty {
            do {
                try await processLauncher.waitForExit(process)
            } catch {
                let waitFailure = PresetExecutionResult(
                    presetID: preset.id,
                    status: .failed,
                    steps: [
                        PresetStepResult(
                            id: UUID(),
                            action: .legacy(name: "waitForExit", value: nil),
                            succeeded: false,
                            failure: PresetStepFailure(message: error.localizedDescription)
                        )
                    ]
                )
                phases.append(waitFailure)
                return GameWorkflowResult(presetID: preset.id, status: .failed, process: process, phaseResults: phases)
            }
        }

        let finalize = await executePhase(presetID: preset.id, name: preset.name, steps: preset.finalizeSteps, policy: policy)
        phases.append(finalize)

        return GameWorkflowResult(
            presetID: preset.id,
            status: finalize.status == .succeeded ? .succeeded : (finalize.status == .cancelled ? .cancelled : .failed),
            process: process,
            phaseResults: phases
        )
    }

    private func executePhase(
        presetID: UUID,
        name: String,
        steps: [PresetStep],
        policy: PresetExecutionPolicy
    ) async -> PresetExecutionResult {
        let phase = Preset(
            id: presetID,
            name: name,
            steps: steps
        )

        if steps.isEmpty {
            return PresetExecutionResult(presetID: presetID, status: .succeeded, steps: [])
        }
        return await stepExecutor.execute(phase, policy: policy)
    }
}
