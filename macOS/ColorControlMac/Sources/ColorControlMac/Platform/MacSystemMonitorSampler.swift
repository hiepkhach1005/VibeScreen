import ColorControlCore
import Darwin
import Foundation
import IOKit.ps

actor MacSystemMonitorSampler: SystemMonitorSampling {
    private struct CPUTicks {
        let active: UInt64
        let idle: UInt64

        var total: UInt64 { active + idle }
    }

    private struct NetworkTotals {
        let receivedBytes: UInt64
        let sentBytes: UInt64
        let capturedAt: Date
    }

    private struct PowerReading {
        let source: SystemPowerSource
        let voltageVolts: Double?
        let currentAmps: Double?
        let estimatedBatteryFlowWatts: Double?
        let adapterRatedWatts: Double?
    }

    private var previousCPUTicks: CPUTicks?
    private var previousNetworkTotals: NetworkTotals?

    func sample() async throws -> SystemMonitorSnapshot {
        try Task.checkCancellation()

        let capturedAt = Date()
        let cpuTicks = try readCPUTicks()
        let cpuUsage = usagePercent(current: cpuTicks, previous: previousCPUTicks)
        previousCPUTicks = cpuTicks

        let memory = try readMemoryUsage()
        let storage = readStorageCapacity()
        let networkTotals = try readNetworkTotals(capturedAt: capturedAt)
        let networkRates = rates(current: networkTotals, previous: previousNetworkTotals)
        previousNetworkTotals = networkTotals
        let power = readPower()

        return SystemMonitorSnapshot(
            capturedAt: capturedAt,
            cpuUsagePercent: cpuUsage,
            // Metal exposes counters for this app's own command buffers, not
            // authoritative whole-system GPU utilization.
            gpuUsagePercent: nil,
            processorCount: ProcessInfo.processInfo.processorCount,
            activeProcessorCount: ProcessInfo.processInfo.activeProcessorCount,
            systemUptimeSeconds: ProcessInfo.processInfo.systemUptime,
            memoryUsedBytes: memory.used,
            memoryTotalBytes: memory.total,
            storageTotalBytes: storage.total,
            storageAvailableBytes: storage.available,
            networkDownloadBytesPerSecond: networkRates?.download,
            networkUploadBytesPerSecond: networkRates?.upload,
            thermalPressure: thermalPressure(),
            // macOS has no documented public application API for SMC sensor
            // temperatures or fan RPM. Keep these explicitly unavailable.
            cpuTemperatureCelsius: nil,
            gpuTemperatureCelsius: nil,
            memoryTemperatureCelsius: nil,
            storageTemperatureCelsius: nil,
            fanRPM: nil,
            powerSource: power.source,
            voltageVolts: power.voltageVolts,
            currentAmps: power.currentAmps,
            estimatedBatteryFlowWatts: power.estimatedBatteryFlowWatts,
            adapterRatedWatts: power.adapterRatedWatts
        )
    }

    private func readCPUTicks() throws -> CPUTicks {
        var info = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride
        )
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, rebound, &count)
            }
        }
        guard result == KERN_SUCCESS else {
            throw SystemMonitorError.hostStatistics(result)
        }

        let user = UInt64(info.cpu_ticks.0)
        let system = UInt64(info.cpu_ticks.1)
        let idle = UInt64(info.cpu_ticks.2)
        let nice = UInt64(info.cpu_ticks.3)
        return CPUTicks(active: user + system + nice, idle: idle)
    }

    private func usagePercent(current: CPUTicks, previous: CPUTicks?) -> Double? {
        guard let previous,
              current.total >= previous.total,
              current.active >= previous.active else {
            return nil
        }
        let totalDelta = current.total - previous.total
        guard totalDelta > 0 else { return 0 }
        let activeDelta = current.active - previous.active
        return min(100, max(0, Double(activeDelta) / Double(totalDelta) * 100))
    }

    private func readMemoryUsage() throws -> (used: UInt64, total: UInt64) {
        var info = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
        )
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, rebound, &count)
            }
        }
        guard result == KERN_SUCCESS else {
            throw SystemMonitorError.hostStatistics(result)
        }

        let total = ProcessInfo.processInfo.physicalMemory
        var pageSize: vm_size_t = 0
        let pageSizeResult = host_page_size(mach_host_self(), &pageSize)
        guard pageSizeResult == KERN_SUCCESS else {
            throw SystemMonitorError.hostStatistics(pageSizeResult)
        }
        // Approximate Activity Monitor's memory-used concept: anonymous/app
        // pages + wired pages + physical compressor pages. File-backed cache
        // and purgeable pages remain reclaimable and are not counted as used.
        let usedPages = UInt64(info.active_count)
            + UInt64(info.inactive_count)
            + UInt64(info.wire_count)
            + UInt64(info.compressor_page_count)
        let reclaimablePages = UInt64(info.external_page_count) + UInt64(info.purgeable_count)
        let netUsedPages = usedPages > reclaimablePages ? usedPages - reclaimablePages : 0
        return (used: min(total, netUsedPages * UInt64(pageSize)), total: total)
    }

    private func readStorageCapacity() -> (total: UInt64, available: UInt64) {
        let keys: Set<URLResourceKey> = [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey
        ]

        guard let values = try? URL(fileURLWithPath: "/").resourceValues(forKeys: keys),
              let total = values.volumeTotalCapacity,
              total > 0 else {
            return (0, 0)
        }

        let available: Int64
        if let important = values.volumeAvailableCapacityForImportantUsage {
            available = Int64(important)
        } else if let fallback = values.volumeAvailableCapacity {
            available = Int64(fallback)
        } else {
            available = 0
        }
        return (UInt64(total), UInt64(max(0, available)))
    }

    private func readNetworkTotals(capturedAt: Date) throws -> NetworkTotals {
        var interfaces: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfaces) == 0, let first = interfaces else {
            throw SystemMonitorError.networkInterfaces(errno)
        }
        defer { freeifaddrs(interfaces) }

        var received: UInt64 = 0
        var sent: UInt64 = 0
        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let interface = cursor {
            let value = interface.pointee
            if let address = value.ifa_addr,
               address.pointee.sa_family == UInt8(AF_LINK),
               value.ifa_flags & UInt32(IFF_LOOPBACK) == 0,
               let data = value.ifa_data?.assumingMemoryBound(to: if_data.self) {
                received &+= UInt64(data.pointee.ifi_ibytes)
                sent &+= UInt64(data.pointee.ifi_obytes)
            }
            cursor = value.ifa_next
        }

        return NetworkTotals(receivedBytes: received, sentBytes: sent, capturedAt: capturedAt)
    }

    private func rates(
        current: NetworkTotals,
        previous: NetworkTotals?
    ) -> (download: Double, upload: Double)? {
        guard let previous,
              current.receivedBytes >= previous.receivedBytes,
              current.sentBytes >= previous.sentBytes else {
            return nil
        }
        let duration = current.capturedAt.timeIntervalSince(previous.capturedAt)
        guard duration > 0 else { return nil }
        return (
            download: Double(current.receivedBytes - previous.receivedBytes) / duration,
            upload: Double(current.sentBytes - previous.sentBytes) / duration
        )
    }

    private func thermalPressure() -> SystemThermalPressure {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return .nominal
        case .fair: return .fair
        case .serious: return .serious
        case .critical: return .critical
        @unknown default: return .unknown
        }
    }

    private func readPower() -> PowerReading {
        let blob = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sourceType = IOPSGetProvidingPowerSourceType(blob).takeUnretainedValue() as String
        let source: SystemPowerSource
        switch sourceType {
        case kIOPSACPowerValue:
            source = .acAdapter
        case kIOPSBatteryPowerValue:
            source = .battery
        default:
            source = .unknown
        }

        var voltageVolts: Double?
        var currentAmps: Double?
        let powerSources = IOPSCopyPowerSourcesList(blob).takeRetainedValue() as Array
        for powerSource in powerSources {
            guard let description = IOPSGetPowerSourceDescription(blob, powerSource)?
                .takeUnretainedValue() as? [String: Any] else {
                continue
            }
            if let millivolts = number(description[kIOPSVoltageKey]) {
                voltageVolts = millivolts / 1_000
            }
            if let milliamps = number(description[kIOPSCurrentKey]) {
                currentAmps = milliamps / 1_000
            }
            if voltageVolts != nil || currentAmps != nil { break }
        }

        let adapterDetails = IOPSCopyExternalPowerAdapterDetails()?.takeRetainedValue() as? [String: Any]
        let adapterRatedWatts = adapterDetails.flatMap { number($0[kIOPSPowerAdapterWattsKey]) }
        let estimatedFlow = voltageVolts.flatMap { voltage in
            currentAmps.map { current in abs(voltage * current) }
        }

        return PowerReading(
            source: source,
            voltageVolts: voltageVolts,
            currentAmps: currentAmps,
            estimatedBatteryFlowWatts: estimatedFlow,
            adapterRatedWatts: adapterRatedWatts
        )
    }

    private func number(_ value: Any?) -> Double? {
        (value as? NSNumber)?.doubleValue
    }
}

private enum SystemMonitorError: LocalizedError {
    case hostStatistics(kern_return_t)
    case networkInterfaces(Int32)

    var errorDescription: String? {
        switch self {
        case let .hostStatistics(code):
            return "macOS host statistics failed with code \(code)."
        case let .networkInterfaces(code):
            return "macOS network interface statistics failed with error \(code)."
        }
    }
}
