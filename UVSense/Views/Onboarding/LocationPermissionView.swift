import SwiftUI
import CoreLocation

struct LocationPermissionView: View {
    @StateObject private var locationService = LocationService.shared
    let onComplete: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Location icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.2), .blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "location.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 16) {
                Text("Enable Location")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("UV Sense needs your location to provide accurate UV index data for your area")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Benefits
            VStack(alignment: .leading, spacing: 16) {
                LocationBenefit(
                    icon: "location.circle",
                    text: "Get real-time UV data for your exact location"
                )
                
                LocationBenefit(
                    icon: "bell.badge",
                    text: "Receive reminders when leaving home"
                )
                
                LocationBenefit(
                    icon: "lock.shield",
                    text: "Your location data stays on your device"
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: {
                    // If already determined (denied/restricted), just proceed
                    if locationService.authorizationStatus == .denied || 
                       locationService.authorizationStatus == .restricted {
                        onComplete()
                    } else {
                        // Request permission
                        locationService.requestLocationPermission()
                        // Check status after a delay
                        checkLocationStatusAndProceed()
                    }
                }) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .onChange(of: locationService.authorizationStatus) { _, newStatus in
            // Proceed to dashboard regardless of permission status
            switch newStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                // User granted permission
                onComplete()
            case .denied, .restricted:
                // User denied permission - still proceed with IP-based location
                onComplete()
            default:
                break
            }
        }
    }
    
    private func checkLocationStatusAndProceed() {
        // Check status after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            switch locationService.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                // Permission granted
                onComplete()
            case .denied, .restricted:
                // Permission denied - proceed with IP-based location
                onComplete()
            case .notDetermined:
                // Still not determined - user might have dismissed the dialog
                // Proceed anyway with IP-based location
                onComplete()
            @unknown default:
                onComplete()
            }
        }
    }
}

struct LocationBenefit: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

