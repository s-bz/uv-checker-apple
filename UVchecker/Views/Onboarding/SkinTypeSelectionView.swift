import SwiftUI

struct SkinTypeSelectionView: View {
    @Binding var selectedType: Int
    @Binding var hasFreckles: Bool
    let onNext: () -> Void
    
    let typeDescriptions = [
        (1, "Type I", "Very fair skin", "Always burns, never tans", Color.pink.opacity(0.2)),
        (2, "Type II", "Fair skin", "Burns easily, tans minimally", Color.orange.opacity(0.2)),
        (3, "Type III", "Medium skin", "Burns moderately, tans gradually", Color.yellow.opacity(0.2)),
        (4, "Type IV", "Olive skin", "Burns minimally, tans well", Color.green.opacity(0.2)),
        (5, "Type V", "Brown skin", "Rarely burns, tans profusely", Color.blue.opacity(0.2)),
        (6, "Type VI", "Dark brown/black skin", "Never burns", Color.purple.opacity(0.2))
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Your Skin Type")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            Text("How does your skin typically react to sun exposure?")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(typeDescriptions, id: \.0) { type, name, skin, reaction, color in
                        Button(action: { selectedType = type }) {
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Text(String(type))
                                            .fontWeight(.semibold)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(skin)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    
                                    Text(reaction)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedType == type {
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
                                        selectedType == type ?
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.accentColor, lineWidth: 2)
                                        : nil
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Freckles toggle
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Additional Information")
                            .font(.headline)
                            .padding(.top)
                        
                        Toggle(isOn: $hasFreckles) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("I have freckles")
                                    .font(.subheadline)
                                Text("Freckles can indicate increased sun sensitivity")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                    }
                }
                .padding()
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
            .padding()
        }
    }
}