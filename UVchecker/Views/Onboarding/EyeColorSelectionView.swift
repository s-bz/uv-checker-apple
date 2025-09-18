import SwiftUI

struct EyeColorSelectionView: View {
    @Binding var selectedEyeColor: EyeColor?
    let onNext: () -> Void
    let onBack: () -> Void
    
    let eyeColorGroups: [(String, [EyeColor])] = [
        ("Light", [.lightBlue, .lightGray, .lightGreen]),
        ("Medium", [.blue, .gray, .green, .hazel]),
        ("Dark", [.lightBrown, .darkBrown, .black])
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Eye Color")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            Text("Select your natural eye color")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(eyeColorGroups, id: \.0) { groupName, colors in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(groupName)
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            ForEach(colors, id: \.self) { color in
                                Button(action: { selectedEyeColor = color }) {
                                    HStack {
                                        Circle()
                                            .fill(eyeColorGradient(for: color))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                        
                                        Text(color.displayName)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if selectedEyeColor == color {
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
                                                selectedEyeColor == color ?
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.accentColor, lineWidth: 2)
                                                : nil
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Skip option
                    Button(action: {
                        selectedEyeColor = nil
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
                .disabled(selectedEyeColor == nil)
                .opacity(selectedEyeColor == nil ? 0.5 : 1)
            }
            .padding()
        }
    }
    
    private func eyeColorGradient(for color: EyeColor) -> LinearGradient {
        let colors: [Color]
        
        switch color {
        case .lightBlue, .blue:
            colors = [.blue.opacity(0.6), .blue.opacity(0.8)]
        case .lightGray, .gray:
            colors = [.gray.opacity(0.5), .gray.opacity(0.7)]
        case .lightGreen, .green:
            colors = [.green.opacity(0.5), .green.opacity(0.7)]
        case .hazel:
            colors = [.brown.opacity(0.4), .green.opacity(0.4)]
        case .lightBrown:
            colors = [.brown.opacity(0.5), .brown.opacity(0.6)]
        case .darkBrown:
            colors = [.brown.opacity(0.7), .brown.opacity(0.9)]
        case .black:
            colors = [.black.opacity(0.8), .black]
        }
        
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}