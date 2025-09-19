import SwiftUI

struct HairColorSelectionView: View {
    @Binding var selectedHairColor: HairColor?
    let onNext: () -> Void
    let onBack: () -> Void
    
    let hairColorGroups: [(String, [HairColor])] = [
        ("Light", [.lightBlonde, .blonde, .darkBlonde]),
        ("Red/Auburn", [.red]),
        ("Brown", [.lightBrown, .brown, .darkBrown]),
        ("Dark", [.black]),
        ("Gray/White", [.gray, .white]),
        ("Other", [.bald])
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Hair Color")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            Text("Select your natural hair color")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(hairColorGroups, id: \.0) { groupName, colors in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(groupName)
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            ForEach(colors, id: \.self) { color in
                                Button(action: { selectedHairColor = color }) {
                                    HStack {
                                        Circle()
                                            .fill(hairColorGradient(for: color))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                        
                                        Text(color.displayName)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if selectedHairColor == color {
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
                                                selectedHairColor == color ?
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
                        selectedHairColor = nil
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
                .disabled(selectedHairColor == nil)
                .opacity(selectedHairColor == nil ? 0.5 : 1)
            }
            .padding()
        }
    }
    
    private func hairColorGradient(for color: HairColor) -> LinearGradient {
        let colors: [Color]
        
        switch color {
        case .red:
            colors = [.red.opacity(0.7), .orange.opacity(0.6)]
        case .lightBlonde:
            colors = [.yellow.opacity(0.2), .yellow.opacity(0.3)]
        case .blonde:
            colors = [.yellow.opacity(0.4), .yellow.opacity(0.5)]
        case .darkBlonde:
            colors = [.yellow.opacity(0.6), .brown.opacity(0.3)]
        case .lightBrown:
            colors = [.brown.opacity(0.4), .brown.opacity(0.5)]
        case .brown:
            colors = [.brown.opacity(0.6), .brown.opacity(0.7)]
        case .darkBrown:
            colors = [.brown.opacity(0.8), .brown.opacity(0.9)]
        case .black:
            colors = [.black.opacity(0.8), .black]
        case .gray:
            colors = [.gray.opacity(0.6), .gray.opacity(0.7)]
        case .white:
            colors = [.gray.opacity(0.2), .gray.opacity(0.3)]
        case .bald:
            colors = [.gray.opacity(0.4), .gray.opacity(0.5)]
        }
        
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}