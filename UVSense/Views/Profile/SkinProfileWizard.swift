import SwiftUI
import SwiftData

enum SkinProfileStep: Int, CaseIterable {
    case skinType
    case eyeColor
    case hairColor
    case tanningResponse
    case complete
}

struct SkinProfileWizard: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: SkinProfileStep = .skinType
    @State private var selectedSkinType: Int?
    @State private var selectedEyeColor: EyeColor?
    @State private var selectedHairColor: HairColor?
    @State private var selectedTanningResponse: TanningResponse?
    
    var body: some View {
        NavigationStack {
            VStack {
                // Progress Indicator
                ProgressView(value: Double(currentStep.rawValue + 1), total: Double(SkinProfileStep.allCases.count))
                    .padding()
                
                // Content
                Group {
                    switch currentStep {
                    case .skinType:
                        ProfileSkinTypeView(
                            selectedType: $selectedSkinType,
                            onContinue: {
                                withAnimation {
                                    currentStep = .eyeColor
                                }
                            },
                            onBack: { dismiss() }
                        )
                    
                    case .eyeColor:
                        ProfileEyeColorView(
                            selectedColor: $selectedEyeColor,
                            onContinue: {
                                withAnimation {
                                    currentStep = .hairColor
                                }
                            },
                            onBack: {
                                withAnimation {
                                    currentStep = .skinType
                                }
                            }
                        )
                    
                    case .hairColor:
                        ProfileHairColorView(
                            selectedColor: $selectedHairColor,
                            onContinue: {
                                withAnimation {
                                    currentStep = .tanningResponse
                                }
                            },
                            onBack: {
                                withAnimation {
                                    currentStep = .eyeColor
                                }
                            }
                        )
                    
                    case .tanningResponse:
                        ProfileTanningView(
                            selectedResponse: $selectedTanningResponse,
                            onContinue: {
                                withAnimation {
                                    currentStep = .complete
                                }
                            },
                            onBack: {
                                withAnimation {
                                    currentStep = .hairColor
                                }
                            }
                        )
                    
                    case .complete:
                        ProfileCompleteView(
                            skinType: selectedSkinType,
                            eyeColor: selectedEyeColor,
                            hairColor: selectedHairColor,
                            tanningResponse: selectedTanningResponse,
                            onComplete: saveProfile
                        )
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                .animation(.easeInOut, value: currentStep)
            }
            .navigationTitle("Skin Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveProfile() {
        guard let skinType = selectedSkinType,
              let eyeColor = selectedEyeColor,
              let hairColor = selectedHairColor,
              let tanningResponse = selectedTanningResponse else {
            return
        }
        
        // Delete any existing profiles
        let descriptor = FetchDescriptor<SkinProfile>()
        if let existingProfiles = try? modelContext.fetch(descriptor) {
            for profile in existingProfiles {
                modelContext.delete(profile)
            }
        }
        
        let profile = SkinProfile(
            fitzpatrickType: skinType,
            eyeColor: eyeColor,
            naturalHairColor: hairColor,
            hasFreckles: false,
            tanningResponse: tanningResponse
        )
        
        modelContext.insert(profile)
        try? modelContext.save()
        
        dismiss()
    }
}

// MARK: - Skin Type Helper
struct FitzpatrickType {
    let value: Int
    let name: String
    let description: String
    
    static let all = [
        FitzpatrickType(value: 1, name: "Type I", description: "Very fair skin, always burns, never tans"),
        FitzpatrickType(value: 2, name: "Type II", description: "Fair skin, burns easily, tans minimally"),
        FitzpatrickType(value: 3, name: "Type III", description: "Medium skin, burns moderately, tans gradually"),
        FitzpatrickType(value: 4, name: "Type IV", description: "Olive skin, burns minimally, tans well"),
        FitzpatrickType(value: 5, name: "Type V", description: "Brown skin, rarely burns, tans profusely"),
        FitzpatrickType(value: 6, name: "Type VI", description: "Dark brown/black skin, never burns")
    ]
}

// MARK: - Step Views

struct ProfileSkinTypeView: View {
    @Binding var selectedType: Int?
    let onContinue: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Select Your Skin Type")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Choose the description that best matches your natural skin color")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(FitzpatrickType.all, id: \.value) { type in
                        SkinTypeCard(
                            type: type,
                            isSelected: selectedType == type.value,
                            onTap: {
                                selectedType = type.value
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Text("Back")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button(action: onContinue) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(selectedType == nil)
            }
            .padding()
        }
    }
}

struct ProfileEyeColorView: View {
    @Binding var selectedColor: EyeColor?
    let onContinue: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Select Your Eye Color")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your natural eye color affects UV sensitivity")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(EyeColor.allCases, id: \.self) { color in
                        SelectionCard(
                            title: color.displayName,
                            description: color.description,
                            icon: color.icon,
                            iconColor: color.iconColor,
                            isSelected: selectedColor == color,
                            onTap: {
                                selectedColor = color
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Text("Back")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button(action: onContinue) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(selectedColor == nil)
            }
            .padding()
        }
    }
}

struct ProfileHairColorView: View {
    @Binding var selectedColor: HairColor?
    let onContinue: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Select Your Hair Color")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your natural hair color (before any coloring)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(HairColor.allCases, id: \.self) { color in
                        SelectionCard(
                            title: color.displayName,
                            description: color.description,
                            icon: "person.fill",
                            iconColor: color.iconColor,
                            isSelected: selectedColor == color,
                            onTap: {
                                selectedColor = color
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Text("Back")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button(action: onContinue) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(selectedColor == nil)
            }
            .padding()
        }
    }
}

struct ProfileTanningView: View {
    @Binding var selectedResponse: TanningResponse?
    let onContinue: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("How Does Your Skin React to Sun?")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Think about what happens after sun exposure without protection")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(TanningResponse.allCases, id: \.self) { response in
                        SelectionCard(
                            title: response.displayName,
                            description: response.description,
                            icon: "sun.max.fill",
                            iconColor: response.iconColor,
                            isSelected: selectedResponse == response,
                            onTap: {
                                selectedResponse = response
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Text("Back")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button(action: onContinue) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(selectedResponse == nil)
            }
            .padding()
        }
    }
}

struct ProfileCompleteView: View {
    let skinType: Int?
    let eyeColor: EyeColor?
    let hairColor: HairColor?
    let tanningResponse: TanningResponse?
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                Text("Profile Complete!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your personalized UV protection plan is ready")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Summary
            VStack(alignment: .leading, spacing: 16) {
                ProfileSummaryRow(label: "Skin Type", value: FitzpatrickType.all.first { $0.value == skinType }?.name ?? "")
                ProfileSummaryRow(label: "Eye Color", value: eyeColor?.displayName ?? "")
                ProfileSummaryRow(label: "Hair Color", value: hairColor?.displayName ?? "")
                ProfileSummaryRow(label: "Tanning Response", value: tanningResponse?.displayName ?? "")
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: onComplete) {
                Text("Finish")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

// MARK: - Supporting Views

struct SkinTypeCard: View {
    let type: FitzpatrickType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.name)
                        .font(.headline)
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(UIColor.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SelectionCard: View {
    let title: String
    let description: String
    let icon: String
    let iconColor: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(UIColor.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProfileSummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Eye Color Extension
extension EyeColor {
    var icon: String {
        "eye"
    }
    
    var iconColor: Color {
        switch self {
        case .lightBlue: return .blue.opacity(0.5)
        case .lightGray: return .gray.opacity(0.5)
        case .lightGreen: return .green.opacity(0.5)
        case .blue: return .blue
        case .gray: return .gray
        case .green: return .green
        case .hazel: return .brown.opacity(0.6)
        case .lightBrown: return .brown.opacity(0.7)
        case .darkBrown: return .brown.opacity(0.9)
        case .black: return .black
        }
    }
    
    var description: String {
        switch self {
        case .lightBlue: return "Pale blue eyes"
        case .lightGray: return "Light gray eyes"
        case .lightGreen: return "Light green eyes"
        case .blue: return "Blue eyes"
        case .gray: return "Gray eyes"
        case .green: return "Green eyes"
        case .hazel: return "Hazel eyes"
        case .lightBrown: return "Light brown eyes"
        case .darkBrown: return "Dark brown eyes"
        case .black: return "Black eyes"
        }
    }
}

// MARK: - Hair Color Extension
extension HairColor {
    var iconColor: Color {
        switch self {
        case .red: return .red.opacity(0.8)
        case .lightBlonde: return .yellow.opacity(0.9)
        case .blonde: return .yellow.opacity(0.8)
        case .darkBlonde: return .yellow.opacity(0.6)
        case .lightBrown: return .brown.opacity(0.5)
        case .brown: return .brown.opacity(0.7)
        case .darkBrown: return .brown.opacity(0.9)
        case .black: return .black
        case .gray: return .gray
        case .white: return .gray.opacity(0.3)
        case .bald: return .gray.opacity(0.5)
        }
    }
    
    var description: String {
        switch self {
        case .red: return "Natural red or auburn hair"
        case .lightBlonde: return "Very light blonde hair"
        case .blonde: return "Blonde hair"
        case .darkBlonde: return "Dark blonde hair"
        case .lightBrown: return "Light brown hair"
        case .brown: return "Medium brown hair"
        case .darkBrown: return "Dark brown hair"
        case .black: return "Black hair"
        case .gray: return "Gray hair"
        case .white: return "White hair"
        case .bald: return "No hair / Bald"
        }
    }
}

// MARK: - Tanning Response Extension
extension TanningResponse {
    var iconColor: Color {
        switch self {
        case .alwaysBurns: return .red
        case .usuallyBurns: return .orange
        case .sometimesBurns: return .yellow
        case .rarelyBurns: return .green
        case .neverBurns: return .brown
        }
    }
    
    var description: String {
        switch self {
        case .alwaysBurns: return "Burns easily, never tans"
        case .usuallyBurns: return "Burns easily, tans minimally"
        case .sometimesBurns: return "Burns moderately, tans gradually"
        case .rarelyBurns: return "Burns minimally, tans easily"
        case .neverBurns: return "Never burns, always tans"
        }
    }
}