import Foundation
import CoreLocation
import SwiftData
import Combine
import MapKit

@MainActor
class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var currentLocationData: LocationData?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isUpdatingLocation = false
    @Published var locationError: LocationError?
    @Published var isAtHome = true
    
    private var continuation: CheckedContinuation<CLLocation?, Error>?
    private var modelContext: ModelContext?
    private var homeRegion: CLCircularRegion?
    private let homeRegionIdentifier = "com.uvchecker.home"
    
    override private init() {
        super.init()
        setupLocationManager()
    }
    
    enum LocationError: LocalizedError {
        case denied
        case restricted
        case unknown
        case geocodingFailed
        case locationUnavailable
        
        var errorDescription: String? {
            switch self {
            case .denied:
                return "Location access denied. Please enable location services in Settings."
            case .restricted:
                return "Location access is restricted."
            case .unknown:
                return "Unknown location error occurred."
            case .geocodingFailed:
                return "Failed to determine location name."
            case .locationUnavailable:
                return "Location currently unavailable."
            }
        }
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // Precise for leave-home detection
        locationManager.distanceFilter = 100 // Update every 100m for better tracking
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.allowsBackgroundLocationUpdates = false
        
        // Check initial authorization status
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationError = authorizationStatus == .denied ? .denied : .restricted
        case .authorizedAlways, .authorizedWhenInUse:
            requestLocation()
        @unknown default:
            locationError = .unknown
        }
    }
    
    func requestLocation() {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            locationError = .denied
            return
        }
        
        isUpdatingLocation = true
        locationError = nil
        locationManager.requestLocation()
    }
    
    func getCurrentLocation() async throws -> CLLocation? {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            requestLocation()
        }
    }
    
    func setManualLocation(latitude: Double, longitude: Double, modelContext: ModelContext? = nil) async {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        self.currentLocation = location
        
        // Geocode to get location name
        await geocodeLocation(location, isManual: true, modelContext: modelContext)
    }
    
    private func geocodeLocation(_ location: CLLocation, isManual: Bool = false, modelContext: ModelContext? = nil) async {
        // Use CLGeocoder for now until we find the proper MapKit replacement
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            if let placemark = placemarks.first {
                let locationData = LocationData(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    cityName: placemark.locality ?? placemark.name ?? "Unknown",
                    regionName: placemark.administrativeArea,
                    countryName: placemark.country ?? "Unknown",
                    isManuallySet: isManual
                )
                
                self.currentLocationData = locationData
                
                // Save to SwiftData if context provided
                if let context = modelContext ?? self.modelContext {
                    // Remove old location data
                    let descriptor = FetchDescriptor<LocationData>()
                    if let existingData = try? context.fetch(descriptor) {
                        for data in existingData {
                            context.delete(data)
                        }
                    }
                    
                    context.insert(locationData)
                    try? context.save()
                }
            }
        } catch {
            locationError = .geocodingFailed
            
            // Create basic location data without geocoding
            let locationData = LocationData(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                cityName: "Unknown Location",
                regionName: nil,
                countryName: "Unknown",
                isManuallySet: isManual
            )
            
            self.currentLocationData = locationData
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadCachedLocation()
    }
    
    private func loadCachedLocation() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<LocationData>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        
        if let cachedLocation = try? context.fetch(descriptor).first {
            self.currentLocationData = cachedLocation
            self.currentLocation = CLLocation(
                latitude: cachedLocation.latitude,
                longitude: cachedLocation.longitude
            )
        }
    }
    
    func startMonitoringSignificantLocationChanges() {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            return
        }
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    func stopMonitoringLocationChanges() {
        locationManager.stopMonitoringSignificantLocationChanges()
    }
    
    // MARK: - Home Region Monitoring
    func setHomeLocation(_ location: CLLocation) {
        // Stop monitoring previous region if exists
        if let existingRegion = homeRegion {
            locationManager.stopMonitoring(for: existingRegion)
        }
        
        // Create new home region (200m radius for home detection)
        homeRegion = CLCircularRegion(
            center: location.coordinate,
            radius: 200, // 200 meters radius
            identifier: homeRegionIdentifier
        )
        homeRegion?.notifyOnEntry = true
        homeRegion?.notifyOnExit = true
        
        // Start monitoring if authorized
        if authorizationStatus == .authorizedAlways {
            if let region = homeRegion {
                locationManager.startMonitoring(for: region)
            }
        }
        
        // Check if currently at home
        if let currentLocation = currentLocation {
            isAtHome = currentLocation.distance(from: location) < 200
        }
    }
    
    func checkIfAtHome() {
        guard let homeRegion = homeRegion,
              let currentLocation = currentLocation else { return }
        
        let homeLocation = CLLocation(
            latitude: homeRegion.center.latitude,
            longitude: homeRegion.center.longitude
        )
        
        isAtHome = currentLocation.distance(from: homeLocation) <= homeRegion.radius
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                requestLocation()
            case .denied:
                locationError = .denied
            case .restricted:
                locationError = .restricted
            default:
                break
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            
            self.currentLocation = location
            self.isUpdatingLocation = false
            
            // Geocode the location
            await geocodeLocation(location, modelContext: modelContext)
            
            // Resume continuation if waiting
            if let continuation = self.continuation {
                continuation.resume(returning: location)
                self.continuation = nil
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.isUpdatingLocation = false
            
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.locationError = .denied
                case .locationUnknown:
                    self.locationError = .locationUnavailable
                default:
                    self.locationError = .unknown
                }
            } else {
                self.locationError = .unknown
            }
            
            // Resume continuation with error if waiting
            if let continuation = self.continuation {
                continuation.resume(throwing: LocationError.locationUnavailable)
                self.continuation = nil
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in
            if region.identifier == homeRegionIdentifier {
                self.isAtHome = true
                // Could trigger notification here that user is back home
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Task { @MainActor in
            if region.identifier == homeRegionIdentifier {
                self.isAtHome = false
                // Trigger leave-home notification for sunscreen reminder
                NotificationCenter.default.post(
                    name: Notification.Name("UserLeftHome"),
                    object: nil
                )
            }
        }
    }
}