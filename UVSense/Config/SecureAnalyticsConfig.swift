import Foundation
import OSLog

/// Secure configuration manager for analytics settings
/// Handles loading PostHog API keys and configuration from secure storage
class SecureAnalyticsConfig {
    private static let logger = Logger(subsystem: "com.infuseproduct.uvsense", category: "SecureConfig")
    
    // MARK: - Configuration Structure
    
    struct PostHogConfig {
        let apiKey: String
        let host: String
        let environment: String
        
        var isValid: Bool {
            return !apiKey.isEmpty && 
                   !host.isEmpty && 
                   apiKey.hasPrefix("phc_") &&
                   host.hasPrefix("https://")
        }
    }
    
    // MARK: - Configuration Loading
    
    /// Load PostHog configuration from secure storage
    /// Priority: Environment Variables > Local Plist > Main Plist > Fallback
    /// - Returns: PostHogConfig if successful, nil if configuration is invalid or missing
    static func loadPostHogConfig() -> PostHogConfig? {
        logger.info("🔒 Loading PostHog configuration from secure storage")
        
        // PRIORITY 1: Environment Variables (for Xcode Cloud builds)
        if let envConfig = loadFromEnvironmentVariables() {
            logger.info("🔒 ✅ PostHog configuration loaded from environment variables")
            return envConfig
        }
        
        // PRIORITY 2: Local Plist File (for local development with real API key)
        if let localConfig = loadFromLocalPlistFile() {
            logger.info("🔒 ✅ PostHog configuration loaded from local plist file")
            return localConfig
        }
        
        // PRIORITY 3: Main Plist File (fallback with placeholder detection)
        if let plistConfig = loadFromMainPlistFile() {
            logger.info("🔒 ✅ PostHog configuration loaded from main plist file")
            return plistConfig
        }
        
        // PRIORITY 4: No valid configuration found
        logger.error("🔒 ❌ No valid PostHog configuration found")
        logger.error("🔒 💡 Setup guide: Create AnalyticsConfig.local.plist or set POSTHOG_API_KEY environment variable")
        return nil
    }
    
    /// Load PostHog configuration from environment variables
    /// Used primarily for Xcode Cloud builds and CI/CD
    private static func loadFromEnvironmentVariables() -> PostHogConfig? {
        logger.info("🔒 Attempting to load PostHog config from environment variables")
        
        guard let apiKey = ProcessInfo.processInfo.environment["POSTHOG_API_KEY"],
              !apiKey.isEmpty else {
            logger.info("🔒 POSTHOG_API_KEY environment variable not found or empty")
            return nil
        }
        
        let host = ProcessInfo.processInfo.environment["POSTHOG_HOST"] ?? "https://us.i.posthog.com"
        let environment = ProcessInfo.processInfo.environment["POSTHOG_ENVIRONMENT"] ?? "production"
        
        let config = PostHogConfig(
            apiKey: apiKey,
            host: host,
            environment: environment
        )
        
        // Validate configuration
        guard config.isValid else {
            logger.error("🔒 ❌ PostHog configuration from environment variables validation failed")
            logger.error("🔒 ❌ API Key valid: \(config.apiKey.hasPrefix("phc_"))")
            logger.error("🔒 ❌ Host valid: \(config.host.hasPrefix("https://"))")
            return nil
        }
        
        // Security check: Never log the full API key
        let maskedApiKey = String(config.apiKey.prefix(8)) + "..." + String(config.apiKey.suffix(4))
        logger.info("🔒 ✅ PostHog configuration from environment variables validated successfully")
        logger.info("🔒 ✅ API Key: \(maskedApiKey)")
        logger.info("🔒 ✅ Host: \(config.host)")
        logger.info("🔒 ✅ Environment: \(config.environment)")
        
        return config
    }
    
    /// Load PostHog configuration from local plist file (git-ignored)
    /// Used for local development with real API key
    private static func loadFromLocalPlistFile() -> PostHogConfig? {
        logger.info("🔒 Attempting to load PostHog config from local plist file")
        
        guard let configPath = Bundle.main.path(forResource: "AnalyticsConfig.local", ofType: "plist") else {
            logger.info("🔒 AnalyticsConfig.local.plist not found (this is normal for Xcode Cloud builds)")
            return nil
        }
        
        return loadConfigFromPath(configPath, source: "local plist")
    }
    
    /// Load PostHog configuration from main plist file
    /// Used as fallback but will reject placeholder values
    private static func loadFromMainPlistFile() -> PostHogConfig? {
        logger.info("🔒 Attempting to load PostHog config from main plist file")
        
        guard let configPath = Bundle.main.path(forResource: "AnalyticsConfig", ofType: "plist") else {
            logger.error("🔒 ❌ AnalyticsConfig.plist not found in app bundle")
            return nil
        }
        
        guard let configData = NSDictionary(contentsOfFile: configPath) else {
            logger.error("🔒 ❌ Failed to load AnalyticsConfig.plist")
            return nil
        }
        
        guard let postHogDict = configData["PostHog"] as? [String: Any] else {
            logger.error("🔒 ❌ PostHog configuration section missing from AnalyticsConfig.plist")
            return nil
        }
        
        guard let apiKey = postHogDict["APIKey"] as? String,
              let host = postHogDict["Host"] as? String,
              let environment = postHogDict["Environment"] as? String else {
            logger.error("🔒 ❌ Required PostHog configuration values missing")
            return nil
        }
        
        // Skip placeholder values - require local config or environment variable
        guard apiKey != "POSTHOG_API_KEY_PLACEHOLDER" else {
            logger.error("🔒 ❌ API key is placeholder value")
            logger.error("🔒 💡 Create AnalyticsConfig.local.plist or set POSTHOG_API_KEY environment variable")
            return nil
        }
        
        let config = PostHogConfig(
            apiKey: apiKey,
            host: host,
            environment: environment
        )
        
        // Validate configuration
        guard config.isValid else {
            logger.error("🔒 ❌ PostHog configuration from plist validation failed")
            return nil
        }
        
        return config
    }
    
    /// Load configuration from a specific plist file path
    private static func loadConfigFromPath(_ path: String, source: String) -> PostHogConfig? {
        guard let configData = NSDictionary(contentsOfFile: path) else {
            logger.error("🔒 ❌ Failed to load configuration from \(source)")
            return nil
        }
        
        guard let postHogDict = configData["PostHog"] as? [String: Any] else {
            logger.error("🔒 ❌ PostHog configuration section missing from \(source)")
            return nil
        }
        
        guard let apiKey = postHogDict["APIKey"] as? String,
              let host = postHogDict["Host"] as? String,
              let environment = postHogDict["Environment"] as? String else {
            logger.error("🔒 ❌ Required PostHog configuration values missing from \(source)")
            return nil
        }
        
        // Skip placeholder values
        guard apiKey != "YOUR_POSTHOG_API_KEY_HERE" && apiKey != "POSTHOG_API_KEY_PLACEHOLDER" else {
            logger.error("🔒 ❌ API key is placeholder value in \(source)")
            return nil
        }
        
        let config = PostHogConfig(
            apiKey: apiKey,
            host: host,
            environment: environment
        )
        
        // Validate configuration
        guard config.isValid else {
            logger.error("🔒 ❌ PostHog configuration from \(source) validation failed")
            logger.error("🔒 ❌ API Key valid: \(config.apiKey.hasPrefix("phc_"))")
            logger.error("🔒 ❌ Host valid: \(config.host.hasPrefix("https://"))")
            return nil
        }
        
        // Security check: Never log the full API key
        let maskedApiKey = String(config.apiKey.prefix(8)) + "..." + String(config.apiKey.suffix(4))
        logger.info("🔒 ✅ PostHog configuration from \(source) validated successfully")
        logger.info("🔒 ✅ API Key: \(maskedApiKey)")
        logger.info("🔒 ✅ Host: \(config.host)")
        logger.info("🔒 ✅ Environment: \(config.environment)")
        
        return config
    }
}