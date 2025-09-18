import SwiftUI

struct WelcomeView: View {
    @Binding var currentStep: OnboardingStep
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Sun Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.yellow.opacity(0.3),
                                Color.orange.opacity(0.2),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse)
            }
            
            VStack(spacing: 8) {
                Text("Welcome to UV Checker")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your personal sun safety companion")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Feature points
            VStack(alignment: .leading, spacing: 24) {
                FeatureRow(
                    icon: "sun.max.trianglebadge.exclamationmark",
                    title: "Real-time UV Index",
                    description: "Get accurate UV readings for your location"
                )
                
                FeatureRow(
                    icon: "timer",
                    title: "Personalized Burn Time",
                    description: "Know exactly how long you can stay in the sun"
                )
                
                FeatureRow(
                    icon: "bell.badge",
                    title: "Smart Reminders",
                    description: "Receive timely sunscreen reminders when leaving home"
                )
                
                FeatureRow(
                    icon: "lock.shield",
                    title: "Privacy First",
                    description: "Your data stays on your device, always"
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    currentStep = .locationPermission
                }
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}