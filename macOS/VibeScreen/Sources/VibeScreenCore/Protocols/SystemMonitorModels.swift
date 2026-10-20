import Foundation

public enum SystemPowerSource: String, Sendable, Equatable {
    case acAdapter
    case battery
    case unknown
}

public enum SystemThermalPressure: String, Sendable, Equatable {
    case nominal
    case fair
    case serious
    case critical
    case unknown
}

public struct SystemMonitorSnapshot: Sendable, Equatable {
    public let capturedAt: Date
    public let cpuUsagePercent: Double?
    public let gpuUsagePercent: Double?
    public let processorCount: Int
    public let activeProcessorCount: Int
    public let systemUptimeSeconds: TimeInterval
    public let memoryUsedBytes: UInt64
    public let memoryTotalBytes: UInt64
    public let storageTotalBytes: UInt64
    public let storageAvailableBytes: UInt64
    public let networkDownloadBytesPerSecond: Double?
    public let networkUploadBytesPerSecond: Double?
    public let thermalPressure: SystemThermalPressure
    public let cpuTemperatureCelsius: Double?
    public let gpuTemperatureCelsius: Double?
    public let memoryTemperatureCelsius: Double?
    public let storageTemperatureCelsius: Double?
    public let fanRPM: Double?
    public let powerSource: SystemPowerSource
    public let voltageVolts: Double?
    public let currentAmps: Double?
    public let estimatedBatteryFlowWatts: Double?
    public let adapterRatedWatts: Double?

    public init(
        capturedAt: Date = Date(),
        cpuUsagePercent: Double? = nil,
        gpuUsagePercent: Double? = nil,
        processorCount: Int = 0,
        activeProcessorCount: Int = 0,
        systemUptimeSeconds: TimeInterval = 0,
        memoryUsedBytes: UInt64 = 0,
        memoryTotalBytes: UInt64 = 0,
        storageTotalBytes: UInt64 = 0,
        storageAvailableBytes: UInt64 = 0,
        networkDownloadBytesPerSecond: Double? = nil,
        networkUploadBytesPerSecond: Double? = nil,
        thermalPressure: SystemThermalPressure = .unknown,
        cpuTemperatureCelsius: Double? = nil,
        gpuTemperatureCelsius: Double? = nil,
        memoryTemperatureCelsius: Double? = nil,
        storageTemperatureCelsius: Double? = nil,
        fanRPM: Double? = nil,
        powerSource: SystemPowerSource = .unknown,
        voltageVolts: Double? = nil,
        currentAmps: Double? = nil,
        estimatedBatteryFlowWatts: Double? = nil,
        adapterRatedWatts: Double? = nil
    ) {
        self.capturedAt = capturedAt
        self.cpuUsagePercent = cpuUsagePercent
        self.gpuUsagePercent = gpuUsagePercent
        self.processorCount = processorCount
        self.activeProcessorCount = activeProcessorCount
        self.systemUptimeSeconds = systemUptimeSeconds
        self.memoryUsedBytes = memoryUsedBytes
        self.memoryTotalBytes = memoryTotalBytes
        self.storageTotalBytes = storageTotalBytes
        self.storageAvailableBytes = storageAvailableBytes
        self.networkDownloadBytesPerSecond = networkDownloadBytesPerSecond
        self.networkUploadBytesPerSecond = networkUploadBytesPerSecond
        self.thermalPressure = thermalPressure
        self.cpuTemperatureCelsius = cpuTemperatureCelsius
        self.gpuTemperatureCelsius = gpuTemperatureCelsius
        self.memoryTemperatureCelsius = memoryTemperatureCelsius
        self.storageTemperatureCelsius = storageTemperatureCelsius
        self.fanRPM = fanRPM
        self.powerSource = powerSource
        self.voltageVolts = voltageVolts
        self.currentAmps = currentAmps
        self.estimatedBatteryFlowWatts = estimatedBatteryFlowWatts
        self.adapterRatedWatts = adapterRatedWatts
    }
}

public protocol SystemMonitorSampling: Sendable {
    func sample() async throws -> SystemMonitorSnapshot
}
