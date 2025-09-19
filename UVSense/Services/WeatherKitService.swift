import Foundation
import WeatherKit
import CoreLocation
import SwiftData
import Combine

@MainActor
class WeatherKitService: ObservableObject {
    static let shared = WeatherKitService()
    
    private let weatherService = WeatherService.shared
    @Published var currentUVData: UVData?
    @Published var hourlyForecast: [HourlyUVData] = []
    @Published var isLoading = false
    @Published var error: WeatherError?
    
    private var lastFetchLocation: CLLocation?
    private var lastFetchTime: Date?
    private let cacheValidityDuration: TimeInterval = 10 * 60 // 10 minutes
    
    private init() {}
    
    enum WeatherError: LocalizedError {
        case locationUnavailable
        case weatherKitError(Error)
        case networkError
        case invalidData
        
        var errorDescription: String? {
            switch self {
            case .locationUnavailable:
                return "Location services are unavailable"
            case .weatherKitError(let error):
                return "Weather service error: \(error.localizedDescription)"
            case .networkError:
                return "Network connection error"
            case .invalidData:
                return "Invalid weather data received"
            }
        }
    }
    
    func fetchWeatherData(
        for location: CLLocation,
        locationName: String,
        modelContext: ModelContext? = nil
    ) async {
        // Check cache validity
        if let lastFetch = lastFetchTime,
           let lastLocation = lastFetchLocation,
           Date().timeIntervalSince(lastFetch) < cacheValidityDuration,
           lastLocation.distance(from: location) < 1000 { // Within 1km
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            // Fetch current weather and hourly forecast
            let weather = try await weatherService.weather(
                for: location,
                including: .current, .hourly
            )
            
            // Process current UV data
            let currentWeather = weather.0
            let uvData = UVData(
                uvIndex: Double(currentWeather.uvIndex.value),
                timestamp: Date(),
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                locationName: locationName,
                temperature: currentWeather.temperature.value,
                weatherCondition: currentWeather.condition.description,
                cloudCover: currentWeather.cloudCover
            )
            
            self.currentUVData = uvData
            
            // Save to SwiftData if context provided
            if let context = modelContext {
                context.insert(uvData)
                try? context.save()
            }
            
            // Process hourly forecast (next 48 hours to include tomorrow)
            let hourlyWeather = weather.1
            let newHourlyData = hourlyWeather.forecast.prefix(48).map { forecast in
                HourlyUVData(
                    uvIndex: Double(forecast.uvIndex.value),
                    hour: forecast.date,
                    temperature: forecast.temperature.value,
                    cloudCover: forecast.cloudCover
                )
            }
            
            // Save hourly data if context provided
            if let context = modelContext {
                // Save new hourly data
                for hourData in newHourlyData {
                    context.insert(hourData)
                }
                try? context.save()
                
                // Just use the new data - WeatherKit already provides all hours we need
                self.hourlyForecast = newHourlyData
            } else {
                self.hourlyForecast = newHourlyData
            }
            
            // Update cache tracking
            lastFetchLocation = location
            lastFetchTime = Date()
            
            // Update widget data
            updateWidgetData(modelContext: modelContext, locationName: locationName)
            
        } catch {
            self.error = .weatherKitError(error)
            
            // Try to load cached data from SwiftData
            if let context = modelContext {
                loadCachedData(from: context, location: location)
            }
        }
        
        isLoading = false
    }
    
    func fetchWeatherData(
        latitude: Double,
        longitude: Double,
        locationName: String,
        modelContext: ModelContext? = nil
    ) async {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        await fetchWeatherData(for: location, locationName: locationName, modelContext: modelContext)
    }
    
    private func loadCachedData(from context: ModelContext, location: CLLocation) {
        // Load most recent UV data near this location
        let fetchDescriptor = FetchDescriptor<UVData>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            let cachedData = try context.fetch(fetchDescriptor)
            
            // Find data within 10km and less than 2 hours old
            if let nearbyData = cachedData.first(where: { data in
                let dataLocation = CLLocation(latitude: data.latitude, longitude: data.longitude)
                let distance = dataLocation.distance(from: location)
                let age = Date().timeIntervalSince(data.timestamp)
                return distance < 10000 && age < 7200 // 10km and 2 hours
            }) {
                self.currentUVData = nearbyData
            }
            
            // Load hourly forecast
            let hourlyDescriptor = FetchDescriptor<HourlyUVData>(
                sortBy: [SortDescriptor(\.hour, order: .forward)]
            )
            let cachedHourly = try context.fetch(hourlyDescriptor)
            
            // Get all hours from today (including past) and tomorrow
            let calendar = Calendar.current
            let now = Date()
            let startOfToday = calendar.startOfDay(for: now)
            let endOfTomorrow = calendar.date(byAdding: .day, value: 2, to: startOfToday)!
            
            // Filter for today and tomorrow's hours and remove duplicates
            var seenHours = Set<Date>()
            self.hourlyForecast = cachedHourly.filter { hourData in
                // Check if in date range
                guard hourData.hour >= startOfToday && hourData.hour < endOfTomorrow else {
                    return false
                }
                
                // Check for duplicate hours (round to hour to handle slight time differences)
                let hourComponent = calendar.dateComponents([.year, .month, .day, .hour], from: hourData.hour)
                let roundedHour = calendar.date(from: hourComponent)!
                
                if seenHours.contains(roundedHour) {
                    return false
                } else {
                    seenHours.insert(roundedHour)
                    return true
                }
            }
            
        } catch {
            print("Failed to load cached data: \(error)")
        }
    }
    
    var todayForecast: [HourlyUVData] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        
        return hourlyForecast.filter { hourData in
            hourData.hour >= startOfToday && hourData.hour <= endOfToday
        }
    }
    
    var tomorrowForecast: [HourlyUVData] {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let startOfTomorrow = calendar.startOfDay(for: tomorrow)
        let endOfTomorrow = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: tomorrow)!
        
        return hourlyForecast.filter { hourData in
            hourData.hour >= startOfTomorrow && hourData.hour <= endOfTomorrow
        }
    }
    
    func calculateSunscreenWindow(threshold: Double = 3.0, todayOnly: Bool = false) -> (start: Date?, end: Date?) {
        guard !hourlyForecast.isEmpty else { return (nil, nil) }
        
        let now = Date()
        let calendar = Calendar.current
        var windowStart: Date?
        var windowEnd: Date?
        var inWindow = false
        
        // Filter hours based on whether we want today only or future hours
        let relevantHours: [HourlyUVData]
        if todayOnly {
            // Only consider today's remaining hours
            let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? now
            relevantHours = hourlyForecast.filter { $0.hour >= now && $0.hour <= endOfToday }
        } else {
            // Consider all future hours
            relevantHours = hourlyForecast.filter { $0.hour >= now }
        }
        
        for hourData in relevantHours {
            if hourData.uvIndex >= threshold {
                if !inWindow {
                    windowStart = hourData.hour
                    inWindow = true
                }
                // Set window end to the END of this hour (add 1 hour)
                windowEnd = hourData.hour.addingTimeInterval(3600) // Add 1 hour
            } else if inWindow {
                break // End of continuous window
            }
        }
        
        return (windowStart, windowEnd)
    }
    
    func peakUVHours() -> (start: Date?, end: Date?, maxUV: Double) {
        guard !hourlyForecast.isEmpty else { return (nil, nil, 0) }
        
        let maxUV = hourlyForecast.map { $0.uvIndex }.max() ?? 0
        guard maxUV > 0 else { return (nil, nil, 0) }
        
        let peakHours = hourlyForecast.filter { abs($0.uvIndex - maxUV) < 0.5 }
        
        return (peakHours.first?.hour, peakHours.last?.hour, maxUV)
    }
    
    // MARK: - Widget Data Update
    
    private func updateWidgetData(modelContext: ModelContext?, locationName: String) {
        // Get current skin profile and sunscreen from model context
        var skinProfile: SkinProfile?
        var sunscreenApplication: SunscreenApplication?
        var locationData: LocationData?
        
        if let context = modelContext {
            // Fetch skin profile
            let profileDescriptor = FetchDescriptor<SkinProfile>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            skinProfile = try? context.fetch(profileDescriptor).first
            
            // Fetch active sunscreen application
            let sunscreenDescriptor = FetchDescriptor<SunscreenApplication>(
                sortBy: [SortDescriptor(\.appliedAt, order: .reverse)]
            )
            let sunscreens = (try? context.fetch(sunscreenDescriptor)) ?? []
            sunscreenApplication = sunscreens.first { !$0.needsReapplication }
            
            // Fetch location data
            let locationDescriptor = FetchDescriptor<LocationData>(
                sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
            )
            locationData = try? context.fetch(locationDescriptor).first
        }
        
        // Update widget shared data
        WidgetDataManager.shared.updateWidgetData(
            uvData: currentUVData,
            skinProfile: skinProfile,
            sunscreenApplication: sunscreenApplication,
            hourlyForecast: hourlyForecast,
            locationData: locationData
        )
    }
}