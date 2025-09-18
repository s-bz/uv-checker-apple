import Foundation
import SwiftData
import CoreLocation

@Model
final class UVData {
    var uvIndex: Double
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var locationName: String
    var temperature: Double?
    var weatherCondition: String?
    var cloudCover: Double?
    
    @Transient
    var location: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    @Transient
    var uvLevel: UVLevel {
        UVLevel(fromIndex: uvIndex)
    }
    
    @Transient
    var isStale: Bool {
        Date().timeIntervalSince(timestamp) > 90 * 60 // 90 minutes
    }
    
    init(
        uvIndex: Double,
        timestamp: Date = Date(),
        latitude: Double,
        longitude: Double,
        locationName: String,
        temperature: Double? = nil,
        weatherCondition: String? = nil,
        cloudCover: Double? = nil
    ) {
        self.uvIndex = uvIndex
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.temperature = temperature
        self.weatherCondition = weatherCondition
        self.cloudCover = cloudCover
    }
}

// MARK: - UVLevel Enum
enum UVLevel: Int, CaseIterable {
    case low = 0        // 0-2
    case moderate = 3   // 3-5
    case high = 6       // 6-7
    case veryHigh = 8   // 8-10
    case extreme = 11   // 11+
    
    init(fromIndex index: Double) {
        switch index {
        case 0..<3:
            self = .low
        case 3..<6:
            self = .moderate
        case 6..<8:
            self = .high
        case 8..<11:
            self = .veryHigh
        default:
            self = .extreme
        }
    }
    
    var color: String {
        switch self {
        case .low:
            return "uvGreen"
        case .moderate:
            return "uvYellow"
        case .high:
            return "uvOrange"
        case .veryHigh:
            return "uvRed"
        case .extreme:
            return "uvPurple"
        }
    }
    
    var description: String {
        switch self {
        case .low:
            return "Low"
        case .moderate:
            return "Moderate"
        case .high:
            return "High"
        case .veryHigh:
            return "Very High"
        case .extreme:
            return "Extreme"
        }
    }
    
    var recommendation: String {
        switch self {
        case .low:
            return "Minimal sun protection required"
        case .moderate:
            return "Take care during midday hours"
        case .high:
            return "Protection required - seek shade during midday"
        case .veryHigh:
            return "Extra protection required - avoid being outside during midday"
        case .extreme:
            return "Stay inside during midday hours - all precautions needed"
        }
    }
}

// MARK: - HourlyUVData
@Model
final class HourlyUVData {
    var uvIndex: Double
    var hour: Date
    var temperature: Double?
    var cloudCover: Double?
    
    @Transient
    var uvLevel: UVLevel {
        UVLevel(fromIndex: uvIndex)
    }
    
    init(
        uvIndex: Double,
        hour: Date,
        temperature: Double? = nil,
        cloudCover: Double? = nil
    ) {
        self.uvIndex = uvIndex
        self.hour = hour
        self.temperature = temperature
        self.cloudCover = cloudCover
    }
}