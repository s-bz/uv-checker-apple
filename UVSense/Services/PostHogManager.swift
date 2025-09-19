import Foundation
import PostHog
import SwiftUI
import OSLog
import Combine

@MainActor
class PostHogManager: ObservableObject {
    static let shared = PostHogManager()
    
    @Published var isEnabled = true
    @Published var featureFlags: [String: Any] = [:]
    
    private var posthog: PostHogSDK?
    private let logger = Logger(subsystem: "com.infuseproduct.uvsense", category: "Analytics")
    
    // Anonymous ID that persists across sessions but is not linked to any PII
    private var anonymousUserId: String {
        if let existingId = UserDefaults.standard.string(forKey: "posthog_anonymous_id") {
            return existingId
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: "posthog_anonymous_id")
            return newId
        }
    }
    
    private var config: SecureAnalyticsConfig.PostHogConfig? {
        return SecureAnalyticsConfig.loadPostHogConfig()
    }
    
    private init() {
        loadUserPreferences()
        setupPostHog()
    }
    
    private func setupPostHog() {
        guard let secureConfig = config else {
            logger.warning("PostHog configuration not found. Analytics disabled.")
            return
        }
        
        let config = PostHogConfig(apiKey: secureConfig.apiKey, host: secureConfig.host)
        
        config.captureScreenViews = false // We'll manually track screens
        config.captureApplicationLifecycleEvents = true
        config.flushAt = 20
        config.maxQueueSize = 1000
        config.maxBatchSize = 50
        config.preloadFeatureFlags = true
        config.personProfiles = .identifiedOnly
        
        #if DEBUG
        config.debug = true
        #endif
        
        PostHogSDK.shared.setup(config)
        posthog = PostHogSDK.shared
        
        logger.info("PostHog initialized with host: \(secureConfig.host)")
        
        // Identify user on startup
        identifyUser()
    }
    
    private func loadUserPreferences() {
        isEnabled = UserDefaults.standard.object(forKey: "analytics_enabled") as? Bool ?? true
    }
    
    func setAnalyticsEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "analytics_enabled")
        
        if enabled {
            posthog?.optIn()
            logger.info("Analytics enabled")
        } else {
            posthog?.optOut()
            logger.info("Analytics disabled")
        }
    }
    
    func identifyUser() {
        guard isEnabled else { return }
        
        // Use anonymous ID that's not linked to any personal data
        let userId = anonymousUserId
        
        // Get skin type if available
        let skinType = UserDefaults.standard.integer(forKey: "selectedSkinType")
        
        // Only include non-PII properties
        let properties: [String: Any] = [
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "platform": "iOS",
            "created_at": ISO8601DateFormatter().string(from: Date()),
            "skin_type": skinType > 0 ? skinType : nil,
            "has_completed_onboarding": UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"),
            "notification_enabled": UserDefaults.standard.bool(forKey: "notificationPermissionGranted"),
            "location_permission": UserDefaults.standard.string(forKey: "locationAuthorizationStatus") ?? "unknown"
        ].compactMapValues { $0 }
        
        posthog?.identify(userId, userProperties: properties)
        logger.info("User identified with anonymous ID")
    }
    
    func reset() {
        posthog?.reset()
        logger.info("User reset")
    }
    
    func capture(_ event: String, properties: [String: Any]? = nil) {
        guard isEnabled else { return }
        
        posthog?.capture(event, properties: properties)
    }
    
    func screen(_ screenTitle: String, properties: [String: Any]? = nil) {
        guard isEnabled else { return }
        
        posthog?.screen(screenTitle, properties: properties)
    }
    
    func alias(_ alias: String) {
        guard isEnabled else { return }
        
        posthog?.alias(alias)
    }
    
    func reloadFeatureFlags(completion: ((Error?) -> Void)? = nil) {
        posthog?.reloadFeatureFlags {
            DispatchQueue.main.async {
                self.updateCachedFeatureFlags()
                completion?(nil)
            }
        }
    }
    
    func isFeatureEnabled(_ flag: String, fallback: Bool = false) -> Bool {
        guard isEnabled else { return fallback }
        
        let value = posthog?.isFeatureEnabled(flag) ?? fallback
        
        capture("$feature_flag_called", properties: [
            "$feature_flag": flag,
            "$feature_flag_response": value
        ])
        
        return value
    }
    
    func getFeatureFlagPayload(_ flag: String) -> Any? {
        guard isEnabled else { return nil }
        
        return posthog?.getFeatureFlagPayload(flag)
    }
    
    func getFeatureFlag(_ flag: String) -> Any? {
        guard isEnabled else { return nil }
        
        return posthog?.getFeatureFlag(flag)
    }
    
    private func updateCachedFeatureFlags() {
        var flags: [String: Any] = [:]
        
        let knownFlags = [
            "new_uv_timeline",
            "enhanced_burn_calculation",
            "ai_skin_recommendations",
            "weather_forecast_extended",
            "premium_features",
            "widget_customization"
        ]
        
        for flag in knownFlags {
            if let value = posthog?.getFeatureFlag(flag) {
                flags[flag] = value
            }
        }
        
        featureFlags = flags
    }
    
    func setUserProperty(_ property: String, value: Any) {
        guard isEnabled else { return }
        
        // Filter out any potential PII
        let allowedProperties = [
            "skin_type", "burn_time_minutes", "sunscreen_spf", "sunscreen_applications_count",
            "widget_added", "notifications_enabled", "location_permission", "app_version"
        ]
        guard allowedProperties.contains(property) else {
            logger.warning("Attempted to set disallowed property: \(property)")
            return
        }
        
        posthog?.capture("$set", properties: [
            "$set": [property: value]
        ])
    }
    
    func setUserProperties(_ properties: [String: Any]) {
        guard isEnabled else { return }
        
        // Filter out any potential PII
        let allowedProperties = [
            "skin_type", "burn_time_minutes", "sunscreen_spf", "sunscreen_applications_count",
            "widget_added", "notifications_enabled", "location_permission", "app_version"
        ]
        let filteredProperties = properties.filter { allowedProperties.contains($0.key) }
        
        if !filteredProperties.isEmpty {
            posthog?.capture("$set", properties: [
                "$set": filteredProperties
            ])
        }
    }
    
    func incrementUserProperty(_ property: String, by value: Int = 1) {
        guard isEnabled else { return }
        
        posthog?.capture("$add", properties: [
            "$add": [property: value]
        ])
    }
    
    func flush() {
        posthog?.flush()
    }
    
    func close() {
        posthog?.close()
    }
}

// MARK: - View Extensions
extension View {
    func postHogScreenView(_ screenName: String, properties: [String: Any]? = nil) -> some View {
        self.onAppear {
            PostHogManager.shared.screen(screenName, properties: properties)
        }
    }
    
    func trackEvent(_ eventName: String, properties: [String: Any]? = nil) -> some View {
        PostHogManager.shared.capture(eventName, properties: properties)
        return self
    }
}

// MARK: - Event Definitions
struct PostHogEvents {
    
    struct App {
        static let launched = "app_launched"
        static let backgrounded = "app_backgrounded"
        static let foregrounded = "app_foregrounded"
        static let terminated = "app_terminated"
        static let widgetInstalled = "widget_installed"
        static let widgetRemoved = "widget_removed"
    }
    
    struct UV {
        static let dataFetched = "uv_data_fetched"
        static let indexViewed = "uv_index_viewed"
        static let burnTimeCalculated = "burn_time_calculated"
        static let peakHoursViewed = "peak_hours_viewed"
        static let alertShown = "uv_alert_shown"
        static let timelineViewed = "uv_timeline_viewed"
        static let timelineHourSelected = "uv_timeline_hour_selected"
        static let tomorrowForecastViewed = "tomorrow_forecast_viewed"
    }
    
    struct Sunscreen {
        static let applied = "sunscreen_applied"
        static let reapplicationReminded = "sunscreen_reapplication_reminded"
        static let reapplicationDismissed = "sunscreen_reapplication_dismissed"
        static let protectionExpired = "sunscreen_protection_expired"
        static let windowCalculated = "sunscreen_window_calculated"
    }
    
    struct SkinProfile {
        static let created = "skin_profile_created"
        static let updated = "skin_profile_updated"
        static let typeSelected = "skin_type_selected"
        static let eyeColorSelected = "eye_color_selected"
        static let hairColorSelected = "hair_color_selected"
        static let tanResponseSelected = "tan_response_selected"
    }
    
    struct Location {
        static let permissionGranted = "location_permission_granted"
        static let permissionDenied = "location_permission_denied"
        static let permissionUpgraded = "location_permission_upgraded"
        static let updated = "location_updated"
        static let manuallySet = "location_manually_set"
        static let ipBasedFallback = "location_ip_based_fallback"
        static let vpnDetected = "location_vpn_detected"
    }
    
    struct Notification {
        static let permissionGranted = "notification_permission_granted"
        static let permissionDenied = "notification_permission_denied"
        static let leaveHomeScheduled = "notification_leave_home_scheduled"
        static let leaveHomeShown = "notification_leave_home_shown"
        static let sunscreenReapplyScheduled = "notification_sunscreen_reapply_scheduled"
        static let sunscreenReapplyShown = "notification_sunscreen_reapply_shown"
    }
    
    struct Onboarding {
        static let started = "onboarding_started"
        static let stepCompleted = "onboarding_step_completed"
        static let completed = "onboarding_completed"
        static let skipped = "onboarding_skipped"
    }
    
    struct Settings {
        static let opened = "settings_opened"
        static let analyticsToggled = "settings_analytics_toggled"
        static let notificationsToggled = "settings_notifications_toggled"
        static let locationSettingsOpened = "settings_location_opened"
        static let profileEdited = "settings_profile_edited"
    }
    
    struct Widget {
        static let viewed = "widget_viewed"
        static let tapped = "widget_tapped"
        static let updated = "widget_updated"
        static let configurationChanged = "widget_configuration_changed"
        static let added = "widget_added"
        static let removed = "widget_removed"
        static let refreshed = "widget_refreshed"
    }
    
    struct Clicks {
        static let refreshData = "click_refresh_data"
        static let applySunscreen = "click_apply_sunscreen"
        static let removeSunscreen = "click_remove_sunscreen"
        static let openSettings = "click_open_settings"
        static let viewUVInfo = "click_view_uv_info"
        static let selectTimelineHour = "click_select_timeline_hour"
        static let expandTomorrowWeather = "click_expand_tomorrow_weather"
        static let dismissNotification = "click_dismiss_notification"
        static let acceptLocationPermission = "click_accept_location_permission"
        static let denyLocationPermission = "click_deny_location_permission"
    }
    
    struct Views {
        static let dashboard = "view_dashboard"
        static let onboarding = "view_onboarding"
        static let settings = "view_settings"
        static let skinProfile = "view_skin_profile"
        static let sunscreenSheet = "view_sunscreen_sheet"
        static let uvTimeline = "view_uv_timeline"
        static let tomorrowWeather = "view_tomorrow_weather"
        static let locationPermission = "view_location_permission"
        static let notificationPermission = "view_notification_permission"
    }
    
    struct Error {
        static let occurred = "error_occurred"
        static let weatherKitError = "error_weatherkit"
        static let locationError = "error_location"
        static let widgetError = "error_widget"
    }
}