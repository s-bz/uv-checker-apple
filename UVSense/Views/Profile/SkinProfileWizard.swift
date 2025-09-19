import SwiftUI
import SwiftData

enum SkinProfileStep: Int, CaseIterable {
    case skinColor
    case eyeColor
    case hairColor
    case tanningResponse
    case complete
}

// Skin color options
struct SkinColorOption {
    let id: String
    let name: String
    let color: Color
    let fitzpatrickType: Int
    
    static let all = [
        SkinColorOption(id: "pearl", name: "Pearl", color: Color(red: 1.0, green: 0.93, blue: 0.89), fitzpatrickType: 1),
        SkinColorOption(id: "opal", name: "Opal", color: Color(red: 1.0, green: 0.88, blue: 0.78), fitzpatrickType: 2),
        SkinColorOption(id: "ivory", name: "Ivory", color: Color(red: 1.0, green: 0.83, blue: 0.73), fitzpatrickType: 2),
        SkinColorOption(id: "creme", name: "Creme", color: Color(red: 0.98, green: 0.78, blue: 0.63), fitzpatrickType: 3),
        SkinColorOption(id: "coco", name: "Coco", color: Color(red: 0.87, green: 0.68, blue: 0.52), fitzpatrickType: 4),
        SkinColorOption(id: "honey", name: "Honey", color: Color(red: 0.76, green: 0.56, blue: 0.41), fitzpatrickType: 4),
        SkinColorOption(id: "tawny", name: "Tawny", color: Color(red: 0.65, green: 0.45, blue: 0.34), fitzpatrickType: 5),
        SkinColorOption(id: "ebony", name: "Ebony", color: Color(red: 0.45, green: 0.31, blue: 0.24), fitzpatrickType: 6)
    ]
}

struct SkinProfileWizard: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: SkinProfileStep = .skinColor
    @State private var selectedSkinColor: SkinColorOption?
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
                    case .skinColor:
                        ProfileSkinColorView(
                            selectedColor: $selectedSkinColor,
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
                                    currentStep = .skinColor
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
                            skinType: selectedSkinColor?.fitzpatrickType,
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
        guard let skinType = selectedSkinColor?.fitzpatrickType,
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

struct ProfileSkinColorView: View {
    @Binding var selectedColor: SkinColorOption?
    let onContinue: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header text
            Text("Select your skin color")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 20)
                .padding(.bottom, 8)
            
            Text("Time to sunburn depends on your skin type.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
            
            // Color palette grid - no scroll needed
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 25),
                GridItem(.flexible(), spacing: 25)
            ], spacing: 20) {
                ForEach(SkinColorOption.all, id: \.id) { option in
                    VStack(spacing: 8) {
                        Circle()
                            .fill(option.color)
                            .frame(width: 75, height: 75)
                            .overlay(
                                Circle()
                                    .stroke(
                                        selectedColor?.id == option.id ? Color.blue : Color.clear,
                                        lineWidth: 3
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                            .scaleEffect(selectedColor?.id == option.id ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: selectedColor?.id)
                            .onTapGesture {
                                selectedColor = option
                            }
                        
                        Text(option.name.lowercased())
                            .font(.footnote)
                            .fontWeight(selectedColor?.id == option.id ? .semibold : .regular)
                            .foregroundColor(selectedColor?.id == option.id ? .primary : .secondary)
                    }
                }
            }
            .padding(.horizontal, 45)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Text("Cancel")
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
            .padding(.horizontal, 20)
            .padding(.bottom, 15)
        }
    }
}

struct ProfileEyeColorView: View {
    @Binding var selectedColor: EyeColor?
    let onContinue: () -> Void
    let onBack: () -> Void
    
    // Reorder eye colors to group similar colors together
    let eyeColorOrder: [EyeColor] = [
        .lightBlue, .blue,           // Blues on same row
        .lightGreen, .green,         // Greens on same row  
        .lightGray, .gray,           // Grays on same row
        .lightBrown, .hazel,         // Light browns on same row
        .darkBrown, .black           // Dark browns on same row
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header text
            Text("Select your eye color")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 15)
                .padding(.bottom, 6)
            
            Text("Your natural eye color affects UV sensitivity")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(.bottom, 15)
            
            // Eye color grid - same layout as skin colors
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 25),
                GridItem(.flexible(), spacing: 25)
            ], spacing: 16) {
                ForEach(eyeColorOrder, id: \.self) { color in
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                            
                            // Eye representation
                            ZStack {
                                // Outer iris
                                Circle()
                                    .fill(color.visualColor)
                                    .frame(width: 60, height: 60)
                                
                                // Inner detail/gradient
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            gradient: Gradient(colors: [
                                                color.visualColor.opacity(0.3),
                                                color.visualColor
                                            ]),
                                            center: .center,
                                            startRadius: 5,
                                            endRadius: 30
                                        )
                                    )
                                    .frame(width: 60, height: 60)
                                
                                // Pupil
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 20, height: 20)
                                
                                // Highlight
                                Circle()
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 7, height: 7)
                                    .offset(x: -4, y: -4)
                            }
                        }
                        .overlay(
                            Circle()
                                .stroke(
                                    selectedColor == color ? Color.blue : Color.clear,
                                    lineWidth: 3
                                )
                                .frame(width: 73, height: 73)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                        .scaleEffect(selectedColor == color ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: selectedColor)
                        .onTapGesture {
                            selectedColor = color
                        }
                        
                        Text(color.displayName.lowercased())
                            .font(.footnote)
                            .fontWeight(selectedColor == color ? .semibold : .regular)
                            .foregroundColor(selectedColor == color ? .primary : .secondary)
                    }
                }
            }
            .padding(.horizontal, 50)
            
            Spacer()
            
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
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
    }
}

struct ProfileHairColorView: View {
    @Binding var selectedColor: HairColor?
    let onContinue: () -> Void
    let onBack: () -> Void
    
    // Organize hair colors logically - light to dark
    let hairColorOrder: [HairColor] = [
        .lightBlonde, .blonde,       // Blondes
        .darkBlonde, .lightBrown,    // Dark blonde/light brown
        .brown, .darkBrown,          // Browns
        .black, .red,                // Black and red
        .gray, .white                // Gray and white
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header text
            Text("Select your hair color")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 15)
                .padding(.bottom, 6)
            
            Text("Your natural hair color (before any coloring)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(.bottom, 15)
            
            // Hair color grid - no scroll needed
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 25),
                GridItem(.flexible(), spacing: 25)
            ], spacing: 16) {
                ForEach(hairColorOrder, id: \.self) { color in
                    VStack(spacing: 6) {
                        // Regular hair color circle with gradient
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        color.visualHairColor.opacity(0.9),
                                        color.visualHairColor
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(
                                        selectedColor == color ? Color.blue : Color.clear,
                                        lineWidth: 3
                                    )
                                    .frame(width: 73, height: 73)
                            )
                        
                        Text(color.displayName.lowercased())
                            .font(.footnote)
                            .fontWeight(selectedColor == color ? .semibold : .regular)
                            .foregroundColor(selectedColor == color ? .primary : .secondary)
                    }
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    .scaleEffect(selectedColor == color ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: selectedColor)
                    .onTapGesture {
                        selectedColor = color
                    }
                }
            }
            .padding(.horizontal, 50)
            
            Spacer()
            
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
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
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
    
    var visualColor: Color {
        switch self {
        case .lightBlue: return Color(red: 0.53, green: 0.81, blue: 0.98)
        case .lightGray: return Color(red: 0.75, green: 0.78, blue: 0.82)
        case .lightGreen: return Color(red: 0.56, green: 0.74, blue: 0.56)
        case .blue: return Color(red: 0.19, green: 0.45, blue: 0.72)
        case .gray: return Color(red: 0.5, green: 0.52, blue: 0.55)
        case .green: return Color(red: 0.29, green: 0.57, blue: 0.36)
        case .hazel: return Color(red: 0.61, green: 0.47, blue: 0.33)
        case .lightBrown: return Color(red: 0.65, green: 0.45, blue: 0.25)
        case .darkBrown: return Color(red: 0.4, green: 0.25, blue: 0.15)
        case .black: return Color(red: 0.15, green: 0.1, blue: 0.08)
        }
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
    var visualHairColor: Color {
        switch self {
        case .red: return Color(red: 0.76, green: 0.28, blue: 0.15)
        case .lightBlonde: return Color(red: 0.98, green: 0.94, blue: 0.75)
        case .blonde: return Color(red: 0.94, green: 0.86, blue: 0.51)
        case .darkBlonde: return Color(red: 0.76, green: 0.65, blue: 0.42)
        case .lightBrown: return Color(red: 0.65, green: 0.52, blue: 0.39)
        case .brown: return Color(red: 0.5, green: 0.35, blue: 0.25)
        case .darkBrown: return Color(red: 0.3, green: 0.2, blue: 0.13)
        case .black: return Color(red: 0.1, green: 0.08, blue: 0.06)
        case .gray: return Color(red: 0.6, green: 0.6, blue: 0.6)
        case .white: return Color(red: 0.95, green: 0.95, blue: 0.95)
        case .bald: return Color(red: 0.8, green: 0.8, blue: 0.8)
        }
    }
    
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