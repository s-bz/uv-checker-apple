import SwiftUI

struct TanningResponseView: View {
    @Binding var selectedResponse: TanningResponse?
    let onNext: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Tanning Response")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            Text("How does your skin tan after sun exposure?")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(TanningResponse.allCases, id: \.self) { response in
                        Button(action: { selectedResponse = response }) {
                            HStack {
                                Image(systemName: iconForResponse(response))
                                    .font(.title2)
                                    .foregroundColor(colorForResponse(response))
                                    .frame(width: 40)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(response.displayName)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(descriptionForResponse(response))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Spacer()
                                
                                if selectedResponse == response {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                        .font(.title2)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.secondarySystemBackground))
                                    .overlay(
                                        selectedResponse == response ?
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.accentColor, lineWidth: 2)
                                        : nil
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Skip option
                    Button(action: {
                        selectedResponse = nil
                        onNext()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.circle")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading) {
                                Text("Skip this step")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Text("You can always add this later")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.tertiarySystemBackground))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            
            HStack(spacing: 16) {
                Button(action: onBack) {
                    Text("Back")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.accentColor, lineWidth: 2)
                        )
                }
                
                Button(action: onNext) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .disabled(selectedResponse == nil)
                .opacity(selectedResponse == nil ? 0.5 : 1)
            }
            .padding()
        }
    }
    
    private func iconForResponse(_ response: TanningResponse) -> String {
        switch response {
        case .alwaysBurns:
            return "flame.fill"
        case .usuallyBurns:
            return "flame"
        case .sometimesBurns:
            return "sun.max"
        case .rarelyBurns:
            return "sun.min"
        case .neverBurns:
            return "checkmark.shield"
        }
    }
    
    private func colorForResponse(_ response: TanningResponse) -> Color {
        switch response {
        case .alwaysBurns:
            return .red
        case .usuallyBurns:
            return .orange
        case .sometimesBurns:
            return .yellow
        case .rarelyBurns:
            return .green
        case .neverBurns:
            return .blue
        }
    }
    
    private func descriptionForResponse(_ response: TanningResponse) -> String {
        switch response {
        case .alwaysBurns:
            return "Skin always burns and peels, never develops a tan"
        case .usuallyBurns:
            return "Skin usually burns first, then develops a light tan"
        case .sometimesBurns:
            return "Skin sometimes burns, gradually develops a moderate tan"
        case .rarelyBurns:
            return "Skin rarely burns, easily develops a good tan"
        case .neverBurns:
            return "Skin never burns, always tans deeply"
        }
    }
}