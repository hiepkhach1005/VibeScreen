import OSLog

enum ColorControlLogger {
    static let app = Logger(subsystem: "com.colorcontrol.mac", category: "app")
    static let automation = Logger(subsystem: "com.colorcontrol.mac", category: "automation")
    static let protocolIO = Logger(subsystem: "com.colorcontrol.mac", category: "protocol")
    static let migration = Logger(subsystem: "com.colorcontrol.mac", category: "migration")
}
