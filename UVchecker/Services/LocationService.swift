import Foundation
import CoreLocation
import SwiftData
import Combine
import MapKit

@MainActor
class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    private let ipLocationService = IPLocationService.shared
    private let networkMonitor = NetworkMonitor.shared
    
    @Published var currentLocation: CLLocation?
    @Published var currentLocationData: LocationData?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isUpdatingLocation = false
    @Published var locationError: LocationError?
    @Published var isAtHome = true
    @Published var isUsingIPLocation = false
    
    private var continuation: CheckedContinuation<CLLocation?, Error>?
    private var modelContext: ModelContext?
    private var homeRegion: CLCircularRegion?
    private let homeRegionIdentifier = "com.uvchecker.home"
    private var cancellables = Set<AnyCancellable>()
    
    override private init() {
        super.init()
        setupLocationManager()
        setupIPLocationMonitoring()
        networkMonitor.start()
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
        
        // If denied/restricted, fall back to IP location immediately
        if authorizationStatus == .denied || authorizationStatus == .restricted {
            Task {
                await fetchIPBasedLocation()
            }
        }
    }
    
    private func setupIPLocationMonitoring() {
        // Listen for IP address changes
        NotificationCenter.default.publisher(for: .ipAddressChanged)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleIPChange()
                }
            }
            .store(in: &cancellables)
        
        // Listen for network path changes
        NotificationCenter.default.publisher(for: .networkPathChanged)
            .sink { [weak self] _ in
                Task { @MainActor in
                    // Only update if using IP location
                    if self?.isUsingIPLocation == true {
                        await self?.fetchIPBasedLocation()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Listen for VPN status changes
        NotificationCenter.default.publisher(for: .vpnStatusChanged)
            .sink { [weak self] notification in
                Task { @MainActor in
                    if self?.isUsingIPLocation == true {
                        let isVPNActive = notification.userInfo?["isActive"] as? Bool ?? false
                        print("VPN status changed to: \(isVPNActive)")
                        await self?.fetchIPBasedLocation()
                    }
                }
            }
            .store(in: &cancellables)
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
    
    func requestAlwaysAuthorization() -> Bool {
        switch authorizationStatus {
        case .authorizedWhenInUse:
            // Can upgrade from WhenInUse to Always
            print("Requesting Always authorization upgrade from When In Use")
            locationManager.requestAlwaysAuthorization()
            return true
        case .notDetermined:
            // First request WhenInUse, then Always
            print("Requesting When In Use authorization first")
            locationManager.requestWhenInUseAuthorization()
            // The Always request will be made after WhenInUse is granted
            return false
        case .authorizedAlways:
            // Already have Always permission
            print("Already have Always authorization, enabling background updates")
            enableBackgroundLocationUpdates()
            return true
        case .denied, .restricted:
            // Can't request if denied or restricted
            print("Location permission denied or restricted")
            locationError = authorizationStatus == .denied ? .denied : .restricted
            return false
        @unknown default:
            locationError = .unknown
            return false
        }
    }
    
    private func enableBackgroundLocationUpdates() {
        // Enable background location updates for leave-home detection
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // Start monitoring significant location changes for power efficiency
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    func hasAlwaysPermission() -> Bool {
        return authorizationStatus == .authorizedAlways
    }
    
    func hasLocationPermission() -> Bool {
        return authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
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
        
        // Start IP monitoring if location is denied
        if authorizationStatus == .denied || authorizationStatus == .restricted {
            ipLocationService.startMonitoring()
        }
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
    
    // MARK: - IP-Based Location Methods
    
    private func fetchIPBasedLocation() async {
        isUpdatingLocation = true
        isUsingIPLocation = true
        
        guard let ipInfo = await ipLocationService.fetchCurrentLocation() else {
            isUpdatingLocation = false
            locationError = .locationUnavailable
            return
        }
        
        // Create location from IP info
        let location = CLLocation(
            latitude: ipInfo.latitude,
            longitude: ipInfo.longitude
        )
        
        self.currentLocation = location
        
        // Determine location type based on VPN status
        let locationType: LocationType = ipInfo.isVPN ? .vpn : .approximate
        
        // Create location data
        let locationData = LocationData(
            latitude: ipInfo.latitude,
            longitude: ipInfo.longitude,
            cityName: ipInfo.city,
            regionName: ipInfo.region,
            countryName: ipInfo.country,
            isManuallySet: false,
            locationType: locationType,
            isVPN: ipInfo.isVPN,
            ipAddress: ipInfo.ip
        )
        
        self.currentLocationData = locationData
        
        // Save to SwiftData
        if let context = modelContext {
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
        
        isUpdatingLocation = false
        
        // Notify about location update
        NotificationCenter.default.post(
            name: .locationUpdatedViaIP,
            object: location,
            userInfo: ["isVPN": ipInfo.isVPN]
        )
    }
    
    private func handleIPChange() async {
        guard isUsingIPLocation else { return }
        
        print("Handling IP address change")
        await fetchIPBasedLocation()
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
            let previousStatus = self.authorizationStatus
            self.authorizationStatus = manager.authorizationStatus
            
            print("Location authorization changed from \(previousStatus) to \(manager.authorizationStatus)")
            
            switch manager.authorizationStatus {
            case .authorizedAlways:
                // When we get Always permission, enable background updates
                enableBackgroundLocationUpdates()
                requestLocation()
                isUsingIPLocation = false
                ipLocationService.stopMonitoring()
                print("Always authorization granted - enabled background updates")
            case .authorizedWhenInUse:
                requestLocation()
                isUsingIPLocation = false
                ipLocationService.stopMonitoring()
                print("When In Use authorization granted")
            case .denied, .restricted:
                // Fall back to IP-based location
                locationError = manager.authorizationStatus == .denied ? .denied : .restricted
                await fetchIPBasedLocation()
                ipLocationService.startMonitoring()
                print("Location authorization denied/restricted - falling back to IP location")
            case .notDetermined:
                print("Location authorization not determined")
            @unknown default:
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