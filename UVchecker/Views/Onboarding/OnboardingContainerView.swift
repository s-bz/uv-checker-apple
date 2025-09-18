import SwiftUI
import SwiftData

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case locationPermission
    case complete
}

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: OnboardingStep = .welcome
    
    var body: some View {
        NavigationStack {
            VStack {
                // Content
                Group {
                    switch currentStep {
                    case .welcome:
                        WelcomeView(currentStep: $currentStep)
                    
                    case .locationPermission:
                        LocationPermissionView(
                            onComplete: {
                                currentStep = .complete
                            },
                            onBack: { currentStep = .welcome }
                        )
                    
                    case .complete:
                        OnboardingCompleteView {
                            dismiss()
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                .animation(.easeInOut, value: currentStep)
            }
            .navigationBarHidden(true)
        }
    }
}