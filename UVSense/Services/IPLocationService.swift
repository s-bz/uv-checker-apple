import Foundation
import Network
import Combine
import CoreLocation

@MainActor
class IPLocationService: ObservableObject {
    static let shared = IPLocationService()
    
    @Published var currentIPLocation: IPLocationInfo?
    @Published var isMonitoring = false
    
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "IPLocationMonitor")
    private var lastKnownIP: String?
    private var ipCache: [String: CachedIPLocation] = [:]
    private let cacheExpiration: TimeInterval = 3600 // 1 hour
    private var ipCheckTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    struct IPLocationInfo {
        let ip: String
        let city: String
        let region: String?
        let country: String
        let countryCode: String?
        let latitude: Double
        let longitude: Double
        let isVPN: Bool
        let isProxy: Bool
        let ispName: String
        let timestamp: Date = Date()
        
        var displayLocation: String {
            if let region = region, !region.isEmpty {
                return "\(city), \(region), \(country)"
            }
            return "\(city), \(country)"
        }
        
        var shortDisplayLocation: String {
            if let region = region, !region.isEmpty {
                return "\(city), \(region)"
            }
            return "\(city), \(country)"
        }
    }
    
    private struct CachedIPLocation {
        let info: IPLocationInfo
        let timestamp: Date
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 3600 // 1 hour
        }
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                if path.status == .satisfied {
                    await self?.checkForIPChange()
                }
            }
        }
        
        monitor.start(queue: monitorQueue)
        
        // Initial fetch
        Task {
            await fetchCurrentLocation()
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        monitor.cancel()
        ipCheckTimer?.invalidate()
    }
    
    func fetchCurrentLocation() async -> IPLocationInfo? {
        // Fetch current IP
        guard let ip = await fetchCurrentIP() else {
            print("Failed to fetch current IP")
            return nil
        }
        
        // Check cache first
        if let cached = ipCache[ip], !cached.isExpired {
            currentIPLocation = cached.info
            return cached.info
        }
        
        // Fetch location for IP
        let locationInfo = await fetchLocationForIP(ip)
        
        // Cache and update
        if let locationInfo = locationInfo {
            ipCache[ip] = CachedIPLocation(info: locationInfo, timestamp: Date())
            currentIPLocation = locationInfo
            lastKnownIP = ip
        }
        
        return locationInfo
    }
    
    // MARK: - Private Methods
    
    private func checkForIPChange() async {
        let newIP = await fetchCurrentIP()
        
        if newIP != lastKnownIP {
            print("IP changed from \(lastKnownIP ?? "none") to \(newIP ?? "none")")
            
            if let ip = newIP {
                lastKnownIP = ip
                await fetchCurrentLocation()
                
                // Notify about IP change
                NotificationCenter.default.post(
                    name: .ipAddressChanged,
                    object: nil,
                    userInfo: ["newIP": ip]
                )
            }
        }
    }
    
    private func fetchCurrentIP() async -> String? {
        // Try IPv4 first (better for geolocation)
        if let ipv4 = await fetchIPv4() {
            return ipv4
        }
        
        // Fallback to any IP
        return await fetchIPGeneral()
    }
    
    private func fetchIPv4() async -> String? {
        guard let url = URL(string: "https://api4.ipify.org?format=json") else { return nil }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let result = try JSONDecoder().decode(IPifyResponse.self, from: data)
                if result.ip.contains(".") && !result.ip.contains(":") {
                    return result.ip
                }
            }
        } catch {
            print("Error fetching IPv4: \(error)")
        }
        
        return nil
    }
    
    private func fetchIPGeneral() async -> String? {
        guard let url = URL(string: "https://api.ipify.org?format=json") else { return nil }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let result = try JSONDecoder().decode(IPifyResponse.self, from: data)
                return result.ip
            }
        } catch {
            print("Error fetching IP: \(error)")
        }
        
        return nil
    }
    
    private func fetchLocationForIP(_ ip: String) async -> IPLocationInfo? {
        // Try primary API first
        if let info = await fetchFromIPAPI(ip) {
            return info
        }
        
        // Fallback to alternative API
        return await fetchFromIPAPIAlternative(ip)
    }
    
    private func fetchFromIPAPI(_ ip: String) async -> IPLocationInfo? {
        guard let url = URL(string: "https://ipapi.co/\(ip)/json/") else { return nil }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let result = try JSONDecoder().decode(IPAPIResponse.self, from: data)
                
                // Check for VPN/proxy
                let vpnStatus = await detectVPNStatus(for: ip)
                
                return IPLocationInfo(
                    ip: ip,
                    city: result.city ?? "Unknown",
                    region: result.region,
                    country: result.country_name ?? result.country ?? "Unknown",
                    countryCode: result.country,
                    latitude: result.latitude ?? 0,
                    longitude: result.longitude ?? 0,
                    isVPN: vpnStatus.isVPN,
                    isProxy: vpnStatus.isProxy,
                    ispName: result.org ?? "Unknown ISP"
                )
            }
        } catch {
            print("Error fetching from ipapi.co: \(error)")
        }
        
        return nil
    }
    
    private func fetchFromIPAPIAlternative(_ ip: String) async -> IPLocationInfo? {
        guard let url = URL(string: "http://ip-api.com/json/\(ip)?fields=status,query,isp,org,city,country,countryCode,regionName,lat,lon,proxy,hosting") else { return nil }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let result = try JSONDecoder().decode(IPAPIAlternativeResponse.self, from: data)
                
                if result.status == "success" {
                    return IPLocationInfo(
                        ip: result.query,
                        city: result.city ?? "Unknown",
                        region: result.regionName,
                        country: result.country ?? "Unknown",
                        countryCode: result.countryCode,
                        latitude: result.lat ?? 0,
                        longitude: result.lon ?? 0,
                        isVPN: result.proxy || result.hosting,
                        isProxy: result.proxy,
                        ispName: result.isp ?? result.org ?? "Unknown ISP"
                    )
                }
            }
        } catch {
            print("Error fetching from ip-api.com: \(error)")
        }
        
        return nil
    }
    
    private func detectVPNStatus(for ip: String) async -> (isVPN: Bool, isProxy: Bool) {
        guard let url = URL(string: "http://ip-api.com/json/\(ip)?fields=proxy,hosting") else {
            return (false, false)
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(VPNDetectionResponse.self, from: data)
            
            let isVPN = result.proxy || result.hosting
            return (isVPN, result.proxy)
        } catch {
            print("Error detecting VPN: \(error)")
            return (false, false)
        }
    }
}

// MARK: - Response Models

private struct IPifyResponse: Codable {
    let ip: String
}

private struct IPAPIResponse: Codable {
    let ip: String?
    let city: String?
    let region: String?
    let country: String?
    let country_name: String?
    let latitude: Double?
    let longitude: Double?
    let org: String?
}

private struct IPAPIAlternativeResponse: Codable {
    let status: String
    let query: String
    let isp: String?
    let org: String?
    let city: String?
    let country: String?
    let countryCode: String?
    let regionName: String?
    let lat: Double?
    let lon: Double?
    let proxy: Bool
    let hosting: Bool
}

private struct VPNDetectionResponse: Codable {
    let proxy: Bool
    let hosting: Bool
}

// MARK: - Notification Names

extension Notification.Name {
    static let ipAddressChanged = Notification.Name("ipAddressChanged")
    static let vpnStatusChanged = Notification.Name("vpnStatusChanged")
}