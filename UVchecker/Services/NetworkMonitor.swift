import Foundation
import Network
import Combine

@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType?
    @Published var isVPNActive = false
    @Published var isExpensive = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var lastPath: NWPath?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.handlePathUpdate(path)
            }
        }
        
        monitor.start(queue: queue)
    }
    
    func stop() {
        monitor.cancel()
    }
    
    private func handlePathUpdate(_ path: NWPath) {
        // Detect changes
        let didChangeInterface = lastPath?.availableInterfaces != path.availableInterfaces
        let didChangeStatus = lastPath?.status != path.status
        
        // Update connection status
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        
        // Detect connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
        } else {
            connectionType = nil
        }
        
        // Check for VPN interfaces
        let hasVPNInterface = path.availableInterfaces.contains { interface in
            // Common VPN interface names
            let vpnPrefixes = ["utun", "ipsec", "ppp"]
            return vpnPrefixes.contains { prefix in
                interface.name.lowercased().hasPrefix(prefix)
            }
        }
        
        let vpnChanged = isVPNActive != hasVPNInterface
        isVPNActive = hasVPNInterface
        
        // Notify about significant changes
        if didChangeInterface || didChangeStatus {
            print("Network path changed - Status: \(path.status), Interfaces: \(path.availableInterfaces.map { $0.name })")
            
            NotificationCenter.default.post(
                name: .networkPathChanged,
                object: nil,
                userInfo: [
                    "isConnected": path.status == .satisfied,
                    "connectionType": connectionType?.description ?? "unknown"
                ]
            )
        }
        
        if vpnChanged {
            print("VPN status changed: \(isVPNActive)")
            
            NotificationCenter.default.post(
                name: .vpnStatusChanged,
                object: nil,
                userInfo: ["isActive": isVPNActive]
            )
        }
        
        lastPath = path
    }
    
    var connectionDescription: String {
        guard isConnected else { return "No Connection" }
        
        switch connectionType {
        case .wifi:
            return "Wi-Fi"
        case .cellular:
            return isExpensive ? "Cellular (Limited)" : "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        default:
            return "Connected"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let networkPathChanged = Notification.Name("networkPathChanged")
    static let locationUpdatedViaIP = Notification.Name("locationUpdatedViaIP")
}

// MARK: - Interface Type Description

extension NWInterface.InterfaceType {
    var description: String {
        switch self {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        case .loopback:
            return "Loopback"
        case .other:
            return "Other"
        @unknown default:
            return "Unknown"
        }
    }
}