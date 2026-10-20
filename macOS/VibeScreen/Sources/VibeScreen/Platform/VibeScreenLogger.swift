import OSLog

enum VibeScreenLogger {
    static let app = Logger(subsystem: "com.vibescreen.mac", category: "app")
    static let automation = Logger(subsystem: "com.vibescreen.mac", category: "automation")
    static let protocolIO = Logger(subsystem: "com.vibescreen.mac", category: "protocol")
    static let migration = Logger(subsystem: "com.vibescreen.mac", category: "migration")
}
