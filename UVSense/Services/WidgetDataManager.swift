//
//  WidgetDataManager.swift
//  UV Sense
//
//  Manages data sharing between app and widget
//

import Foundation
import SwiftData
import CoreLocation
#if canImport(WidgetKit)
import WidgetKit
#endif

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
    private let appGroupIdentifier = "group.com.infuseproduct.UVSense"
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    private let dataKey = "widgetSharedData"
    
    // MARK: - Write Data (from main app)
    
    func updateWidgetData(
        uvData: UVData?,
        skinProfile: SkinProfile?,
        sunscreenApplication: SunscreenApplication?,
        hourlyForecast: [HourlyUVData],
        locationData: LocationData?
    ) {
        guard let uvData = uvData else { return }
        
        // Calculate burn time if we have skin profile
        var burnTime: Int?
        if let profile = skinProfile {
            let burnTimeResult = BurnTimeCalculator.calculateBurnTime(
                skinProfile: profile,
                uvIndex: uvData.uvIndex,
                sunscreen: sunscreenApplication,
                cloudCover: uvData.cloudCover
            )
            burnTime = burnTimeResult.burnTimeMinutes
        }
        
        // Find next high UV time (UV >= 6)
        let nextHighUV = hourlyForecast
            .filter { $0.hour > Date() && $0.uvIndex >= 6 }
            .first?.hour
        
        // Convert hourly forecast
        let hourlyData = hourlyForecast.prefix(24).map { hourData in
            WidgetSharedData.HourlyForecast(
                hour: hourData.hour,
                uvIndex: hourData.uvIndex,
                temperature: hourData.temperature
            )
        }
        
        // Create shared data
        let sharedData = WidgetSharedData(
            uvIndex: uvData.uvIndex,
            uvLevel: uvData.uvLevel.description,
            location: locationData?.shortDisplayName ?? uvData.locationName,
            latitude: uvData.latitude,
            longitude: uvData.longitude,
            temperature: uvData.temperature,
            weatherCondition: uvData.weatherCondition,
            cloudCover: uvData.cloudCover,
            burnTime: burnTime,
            sunscreenActive: sunscreenApplication != nil && !sunscreenApplication!.needsReapplication,
            sunscreenSPF: sunscreenApplication?.spfValue,
            sunscreenAppliedAt: sunscreenApplication?.appliedAt,
            nextHighUVTime: nextHighUV,
            lastUpdated: Date(),
            hourlyForecast: hourlyData
        )
        
        // Save to shared defaults
        if let encoded = try? JSONEncoder().encode(sharedData) {
            sharedDefaults?.set(encoded, forKey: dataKey)
            
            // Trigger widget timeline refresh
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        }
    }
    
    // MARK: - Read Data (from widget)
    
    func getSharedData() -> WidgetSharedData? {
        guard let data = sharedDefaults?.data(forKey: dataKey),
              let sharedData = try? JSONDecoder().decode(WidgetSharedData.self, from: data) else {
            return nil
        }
        
        return sharedData
    }
    
    // MARK: - Clear Data
    
    func clearSharedData() {
        sharedDefaults?.removeObject(forKey: dataKey)
    }
}