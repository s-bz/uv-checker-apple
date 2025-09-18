import Foundation
import SwiftData
import CoreLocation

@Model
final class LocationData {
    var latitude: Double
    var longitude: Double
    var cityName: String
    var regionName: String?
    var countryName: String
    var lastUpdated: Date
    var isManuallySet: Bool
    
    @Transient
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    @Transient
    var displayName: String {
        var components: [String] = []
        
        components.append(cityName)
        
        if let region = regionName, !region.isEmpty {
            components.append(region)
        }
        
        components.append(countryName)
        
        return components.joined(separator: ", ")
    }
    
    @Transient
    var shortDisplayName: String {
        if let region = regionName, !region.isEmpty {
            return "\(cityName), \(region)"
        }
        return "\(cityName), \(countryName)"
    }
    
    @Transient
    var isStale: Bool {
        Date().timeIntervalSince(lastUpdated) > 30 * 60 // 30 minutes
    }
    
    init(
        latitude: Double,
        longitude: Double,
        cityName: String,
        regionName: String? = nil,
        countryName: String,
        isManuallySet: Bool = false
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.cityName = cityName
        self.regionName = regionName
        self.countryName = countryName
        self.lastUpdated = Date()
        self.isManuallySet = isManuallySet
    }
    
    func updateLocation(
        latitude: Double,
        longitude: Double,
        cityName: String,
        regionName: String? = nil,
        countryName: String
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.cityName = cityName
        self.regionName = regionName
        self.countryName = countryName
        self.lastUpdated = Date()
    }
}