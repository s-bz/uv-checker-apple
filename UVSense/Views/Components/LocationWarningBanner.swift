import SwiftUI

struct LocationWarningBanner: View {
    let locationData: LocationData?
    let onEnablePreciseLocation: () -> Void
    let onDismiss: () -> Void
    
    @State private var isDismissed = false
    @AppStorage("hideLocationWarning") private var permanentlyHidden = false
    
    var body: some View {
        if !isDismissed && !permanentlyHidden, 
           let locationData = locationData,
           locationData.locationType != .precise {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    // Icon
                    Image(systemName: warningIcon)
                        .font(.title3)
                        .foregroundColor(warningColor)
                    
                    // Text content
                    VStack(alignment: .leading, spacing: 6) {
                        Text(warningTitle)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(warningMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Action buttons
                        HStack(spacing: 12) {
                            Button(action: onEnablePreciseLocation) {
                                Label("Enable Precise Location", systemImage: "location.fill")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isDismissed = true
                                }
                                onDismiss()
                            }) {
                                Text("Dismiss")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(.top, 4)
                    }
                    
                    Spacer()
                    
                    // Close button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isDismissed = true
                        }
                        onDismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
                .padding()
                .background(bannerBackground)
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
    
    private var warningIcon: String {
        guard let locationData = locationData else { return "exclamationmark.triangle" }
        
        switch locationData.locationType {
        case .vpn:
            return "lock.shield"
        case .approximate:
            return "location.slash"
        case .manual:
            return "hand.point.up.left"
        case .precise:
            return "location.fill"
        }
    }
    
    private var warningColor: Color {
        guard let locationData = locationData else { return .yellow }
        
        switch locationData.locationType {
        case .vpn:
            return .orange
        case .approximate:
            return .yellow
        case .manual:
            return .blue
        case .precise:
            return .green
        }
    }
    
    private var warningTitle: String {
        guard let locationData = locationData else { return "Location Unavailable" }
        
        switch locationData.locationType {
        case .vpn:
            return "VPN Detected - Showing VPN Location"
        case .approximate:
            return "Using Approximate Location"
        case .manual:
            return "Using Manual Location"
        case .precise:
            return "Using Precise Location"
        }
    }
    
    private var warningMessage: String {
        guard let locationData = locationData else { 
            return "Unable to determine your location. UV data may not be accurate."
        }
        
        switch locationData.locationType {
        case .vpn:
            return "UV data is for \(locationData.shortDisplayName). This is your VPN server location, not your actual location."
        case .approximate:
            return "Location based on IP address. UV data for \(locationData.shortDisplayName) may not be accurate for your exact location."
        case .manual:
            return "You've manually set your location to \(locationData.shortDisplayName)."
        case .precise:
            return "Using your current location for accurate UV data."
        }
    }
    
    private var bannerBackground: some View {
        Group {
            if let locationData = locationData {
                switch locationData.locationType {
                case .vpn:
                    Color.orange.opacity(0.15)
                case .approximate:
                    Color.yellow.opacity(0.15)
                case .manual:
                    Color.blue.opacity(0.15)
                case .precise:
                    Color.green.opacity(0.15)
                }
            } else {
                Color.gray.opacity(0.15)
            }
        }
    }
}

// MARK: - Compact Banner for Space-Constrained Views

struct CompactLocationWarningBanner: View {
    let locationData: LocationData?
    let onTap: () -> Void
    
    var body: some View {
        if let locationData = locationData,
           locationData.locationType != .precise {
            Button(action: onTap) {
                HStack(spacing: 8) {
                    Image(systemName: iconForType(locationData.locationType))
                        .font(.caption)
                    
                    Text(textForType(locationData.locationType))
                        .font(.caption)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(backgroundForType(locationData.locationType))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func iconForType(_ type: LocationType) -> String {
        switch type {
        case .vpn: return "lock.shield"
        case .approximate: return "location.slash"
        case .manual: return "hand.point.up.left"
        case .precise: return "location.fill"
        }
    }
    
    private func textForType(_ type: LocationType) -> String {
        switch type {
        case .vpn: return "VPN Location"
        case .approximate: return "Approximate Location"
        case .manual: return "Manual Location"
        case .precise: return "Precise Location"
        }
    }
    
    private func backgroundForType(_ type: LocationType) -> Color {
        switch type {
        case .vpn: return .orange.opacity(0.15)
        case .approximate: return .yellow.opacity(0.15)
        case .manual: return .blue.opacity(0.15)
        case .precise: return .green.opacity(0.15)
        }
    }
}

// MARK: - Preview

struct LocationWarningBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // VPN Warning
            LocationWarningBanner(
                locationData: {
                    let data = LocationData(
                        latitude: 51.5074,
                        longitude: -0.1278,
                        cityName: "London",
                        regionName: nil,
                        countryName: "UK",
                        isManuallySet: false,
                        locationType: .vpn,
                        isVPN: true
                    )
                    return data
                }(),
                onEnablePreciseLocation: {},
                onDismiss: {}
            )
            
            // Approximate Location Warning
            LocationWarningBanner(
                locationData: {
                    let data = LocationData(
                        latitude: 37.7749,
                        longitude: -122.4194,
                        cityName: "San Francisco",
                        regionName: "CA",
                        countryName: "USA",
                        isManuallySet: false,
                        locationType: .approximate,
                        isVPN: false
                    )
                    return data
                }(),
                onEnablePreciseLocation: {},
                onDismiss: {}
            )
            
            Spacer()
        }
        .padding()
    }
}