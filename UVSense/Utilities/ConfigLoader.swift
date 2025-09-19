import Foundation
import OSLog

final class ConfigLoader: @unchecked Sendable {
    static let shared = ConfigLoader()
    
    private let config: [String: String]
    private static let logger = Logger(subsystem: "com.infuseproduct.uvsense", category: "ConfigLoader")
    
    private init() {
        self.config = Self.loadConfig()
    }
    
    private static func loadConfig() -> [String: String] {
        // Debug: Log current working directory and environment
        logger.info("🔍 Current bundle path: \(Bundle.main.bundlePath)")
        logger.info("🔍 SRCROOT: \(ProcessInfo.processInfo.environment["SRCROOT"] ?? "not set")")
        logger.info("🔍 PROJECT_DIR: \(ProcessInfo.processInfo.environment["PROJECT_DIR"] ?? "not set")")
        
        // Try multiple paths where the Secrets.xcconfig might be
        // Prefer local config with actual keys over template
        let possiblePaths = [
            // Direct path from project root
            "/Users/samb/GitHub/UVchecker/UVSense/Config/Secrets.local.xcconfig",
            "/Users/samb/GitHub/UVchecker/UVSense/Config/Secrets.xcconfig",
            
            // Local config with actual keys (not committed)
            Bundle.main.bundlePath + "/../../Config/Secrets.local.xcconfig",
            Bundle.main.bundlePath + "/../../../UVSense/Config/Secrets.local.xcconfig",
            ProcessInfo.processInfo.environment["SRCROOT"].map { $0 + "/Config/Secrets.local.xcconfig" },
            ProcessInfo.processInfo.environment["SRCROOT"].map { $0 + "/UVSense/Config/Secrets.local.xcconfig" },
            ProcessInfo.processInfo.environment["PROJECT_DIR"].map { $0 + "/Config/Secrets.local.xcconfig" },
            ProcessInfo.processInfo.environment["PROJECT_DIR"].map { $0 + "/UVSense/Config/Secrets.local.xcconfig" },
            
            // Fallback to regular config (template)
            Bundle.main.bundlePath + "/../../Config/Secrets.xcconfig",
            Bundle.main.bundlePath + "/../../../UVSense/Config/Secrets.xcconfig",
            ProcessInfo.processInfo.environment["SRCROOT"].map { $0 + "/Config/Secrets.xcconfig" },
            ProcessInfo.processInfo.environment["SRCROOT"].map { $0 + "/UVSense/Config/Secrets.xcconfig" },
            ProcessInfo.processInfo.environment["PROJECT_DIR"].map { $0 + "/Config/Secrets.xcconfig" },
            ProcessInfo.processInfo.environment["PROJECT_DIR"].map { $0 + "/UVSense/Config/Secrets.xcconfig" }
        ].compactMap { $0 }
        
        // Try to find and read the config file
        logger.info("🔍 Checking paths for Secrets.xcconfig:")
        for path in possiblePaths {
            logger.debug("  Checking: \(path)")
            if FileManager.default.fileExists(atPath: path) {
                logger.info("✅ Found Secrets.xcconfig at: \(path)")
                if let contents = try? String(contentsOfFile: path, encoding: .utf8) {
                    let parsedConfig = parseConfig(contents)
                    logger.info("✅ Successfully loaded Secrets.xcconfig with \(parsedConfig.count) keys")
                    return parsedConfig
                } else {
                    logger.error("❌ Found file but couldn't read it: \(path)")
                }
            }
        }
        
        logger.warning("❌ Could not find Secrets.xcconfig in any of the expected locations")
        logger.warning("  Paths checked: \(possiblePaths)")
        return [:]
    }
    
    private static func parseConfig(_ contents: String) -> [String: String] {
        let lines = contents.components(separatedBy: .newlines)
        var config: [String: String] = [:]
        
        for line in lines {
            // Skip comments and empty lines
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("//") {
                continue
            }
            
            // Parse KEY = VALUE pairs
            let parts = trimmedLine.split(separator: "=", maxSplits: 1).map { 
                $0.trimmingCharacters(in: .whitespaces) 
            }
            
            if parts.count == 2 {
                config[parts[0]] = parts[1]
            }
        }
        
        return config
    }
    
    func getValue(for key: String) -> String? {
        return config[key]
    }
    
    var posthogAPIKey: String? {
        return getValue(for: "POSTHOG_API_KEY")
    }
    
    var posthogHost: String? {
        return getValue(for: "POSTHOG_HOST")
    }
}