import Foundation
import SwiftData
import CoreLocation

enum LocationType: Int, Codable {
    case precise = 0      // GPS-based
    case approximate = 1  // IP-based, no VPN
    case vpn = 2         // IP-based with VPN
    case manual = 3      // User-set
}

@Model
final class LocationData {
    var latitude: Double
    var longitude: Double
    var cityName: String
    var regionName: String?
    var countryName: String
    var lastUpdated: Date
    var isManuallySet: Bool
    var locationTypeRaw: Int = 0
    var isVPN: Bool = false
    var ipAddress: String?
    var vpnServerName: String?
    
    @Transient
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    @Transient
    var locationType: LocationType {
        get { LocationType(rawValue: locationTypeRaw) ?? .precise }
        set { locationTypeRaw = newValue.rawValue }
    }
    
    @Transient
    var accuracyWarning: String? {
        switch locationType {
        case .approximate:
            return "Using approximate location based on IP address"
        case .vpn:
            return "Using VPN location - this is your VPN server location, not your actual location"
        case .precise, .manual:
            return nil
        }
    }
    
    @Transient
    var locationIcon: String {
        switch locationType {
        case .precise:
            return "location.fill"
        case .approximate:
            return "location"
        case .vpn:
            return "lock.shield"
        case .manual:
            return "hand.point.up.left"
        }
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
        } else {
            return "\(cityName), \(countryName)"
        }
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
        isManuallySet: Bool = false,
        locationType: LocationType = .precise,
        isVPN: Bool = false,
        ipAddress: String? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.cityName = cityName
        self.regionName = regionName
        self.countryName = countryName
        self.lastUpdated = Date()
        self.isManuallySet = isManuallySet
        self.locationTypeRaw = locationType.rawValue
        self.isVPN = isVPN
        self.ipAddress = ipAddress
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