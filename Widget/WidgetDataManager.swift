//
//  WidgetDataManager.swift
//  Widget
//
//  Manages data sharing between app and widget (Widget side)
//

import Foundation

struct WidgetSharedData: Codable {
    let uvIndex: Double
    let uvLevel: String
    let location: String
    let latitude: Double
    let longitude: Double
    let temperature: Double?
    let weatherCondition: String?
    let cloudCover: Double?
    let burnTime: Int? // in minutes
    let sunscreenActive: Bool
    let sunscreenSPF: Int?
    let sunscreenAppliedAt: Date?
    let nextHighUVTime: Date?
    let lastUpdated: Date
    let hourlyForecast: [HourlyForecast]?
    
    struct HourlyForecast: Codable {
        let hour: Date
        let uvIndex: Double
        let temperature: Double?
    }
}

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    // App Group identifier - must match in both app and widget entitlements
    private let appGroupIdentifier = "group.com.infuseproduct.UVchecker"
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    private let dataKey = "widgetSharedData"
    
    // MARK: - Read Data (from widget)
    
    func getSharedData() -> WidgetSharedData? {
        guard let data = sharedDefaults?.data(forKey: dataKey),
              let sharedData = try? JSONDecoder().decode(WidgetSharedData.self, from: data) else {
            return nil
        }
        
        // Check if data is too old (more than 2 hours)
        let maxAge: TimeInterval = 2 * 60 * 60 // 2 hours
        if Date().timeIntervalSince(sharedData.lastUpdated) > maxAge {
            return nil
        }
        
        return sharedData
    }
    
    // MARK: - Check Data Freshness
    
    func isDataStale() -> Bool {
        guard let sharedData = getSharedData() else { return true }
        
        // Consider data stale if older than 90 minutes
        let staleThreshold: TimeInterval = 90 * 60
        return Date().timeIntervalSince(sharedData.lastUpdated) > staleThreshold
    }
}