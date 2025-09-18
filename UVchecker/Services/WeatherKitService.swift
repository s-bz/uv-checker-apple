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
            
            // Process hourly forecast (next 24 hours)
            let hourlyWeather = weather.1
            self.hourlyForecast = hourlyWeather.forecast.prefix(24).map { forecast in
                HourlyUVData(
                    uvIndex: Double(forecast.uvIndex.value),
                    hour: forecast.date,
                    temperature: forecast.temperature.value,
                    cloudCover: forecast.cloudCover
                )
            }
            
            // Save hourly data if context provided
            if let context = modelContext {
                for hourData in self.hourlyForecast {
                    context.insert(hourData)
                }
                try? context.save()
            }
            
            // Update cache tracking
            lastFetchLocation = location
            lastFetchTime = Date()
            
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
            
            // Filter for future hours only
            self.hourlyForecast = cachedHourly.filter { $0.hour > Date() }.prefix(24).map { $0 }
            
        } catch {
            print("Failed to load cached data: \(error)")
        }
    }
    
    func calculateSunscreenWindow(threshold: Double = 3.0) -> (start: Date?, end: Date?) {
        guard !hourlyForecast.isEmpty else { return (nil, nil) }
        
        var windowStart: Date?
        var windowEnd: Date?
        var inWindow = false
        
        for hourData in hourlyForecast {
            if hourData.uvIndex >= threshold {
                if !inWindow {
                    windowStart = hourData.hour
                    inWindow = true
                }
                windowEnd = hourData.hour
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
}