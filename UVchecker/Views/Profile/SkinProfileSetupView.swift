import SwiftUI
import SwiftData

struct SkinProfileSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType = 3 // Default to Type III
    @State private var eyeColor: EyeColor?
    @State private var hairColor: HairColor?
    @State private var hasFreckles = false
    @State private var tanningResponse: TanningResponse?
    
    @State private var currentStep = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                // Progress indicator
                ProgressView(value: Double(currentStep + 1), total: 3)
                    .padding()
                
                TabView(selection: $currentStep) {
                    // Step 1: Fitzpatrick Type
                    FitzpatrickSelectionView(selectedType: $selectedType)
                        .tag(0)
                    
                    // Step 2: Refinement Attributes (Optional)
                    RefinementAttributesView(
                        eyeColor: $eyeColor,
                        hairColor: $hairColor,
                        hasFreckles: $hasFreckles,
                        tanningResponse: $tanningResponse
                    )
                    .tag(1)
                    
                    // Step 3: Summary
                    ProfileSummaryView(
                        fitzpatrickType: selectedType,
                        eyeColor: eyeColor,
                        hairColor: hairColor,
                        hasFreckles: hasFreckles,
                        tanningResponse: tanningResponse
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            currentStep -= 1
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    if currentStep < 2 {
                        Button("Next") {
                            currentStep += 1
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Complete") {
                            saveProfile()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
            .navigationTitle("Skin Profile Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if currentStep > 0 {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Skip") {
                            // Save with just the basic type
                            saveProfile()
                        }
                    }
                }
            }
        }
    }
    
    private func saveProfile() {
        let profile = SkinProfile(
            fitzpatrickType: selectedType,
            eyeColor: eyeColor,
            naturalHairColor: hairColor,
            hasFreckles: hasFreckles,
            tanningResponse: tanningResponse
        )
        
        // Remove any existing profiles
        let descriptor = FetchDescriptor<SkinProfile>()
        if let existingProfiles = try? modelContext.fetch(descriptor) {
            for existing in existingProfiles {
                modelContext.delete(existing)
            }
        }
        
        modelContext.insert(profile)
        try? modelContext.save()
        
        dismiss()
    }
}

struct FitzpatrickSelectionView: View {
    @Binding var selectedType: Int
    
    let typeDescriptions = [
        (1, "Type I", "Very fair skin", "Always burns, never tans", "👤", Color.pink.opacity(0.3)),
        (2, "Type II", "Fair skin", "Burns easily, tans minimally", "👤", Color.orange.opacity(0.3)),
        (3, "Type III", "Medium skin", "Burns moderately, tans gradually", "👤", Color.yellow.opacity(0.3)),
        (4, "Type IV", "Olive skin", "Burns minimally, tans well", "👤", Color.green.opacity(0.3)),
        (5, "Type V", "Brown skin", "Rarely burns, tans profusely", "👤", Color.blue.opacity(0.3)),
        (6, "Type VI", "Dark brown/black skin", "Never burns", "👤", Color.purple.opacity(0.3))
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Your Skin Type")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            Text("Choose the option that best describes how your skin reacts to sun exposure")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(typeDescriptions, id: \.0) { type, name, skin, reaction, emoji, color in
                        Button(action: { selectedType = type }) {
                            HStack(spacing: 16) {
                                Text(emoji)
                                    .font(.largeTitle)
                                    .frame(width: 50, height: 50)
                                    .background(color)
                                    .clipShape(Circle())
                                
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
                }
                .padding()
            }
        }
    }
}

struct RefinementAttributesView: View {
    @Binding var eyeColor: EyeColor?
    @Binding var hairColor: HairColor?
    @Binding var hasFreckles: Bool
    @Binding var tanningResponse: TanningResponse?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Refine Your Profile")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            Text("Optional: These details help us provide more accurate burn time estimates")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Form {
                Section("Eye Color") {
                    ForEach(EyeColor.allCases, id: \.self) { color in
                        Button(action: { eyeColor = color }) {
                            HStack {
                                Text(color.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if eyeColor == color {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                
                Section("Natural Hair Color") {
                    ForEach(HairColor.allCases, id: \.self) { color in
                        Button(action: { hairColor = color }) {
                            HStack {
                                Text(color.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if hairColor == color {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                
                Section("Skin Characteristics") {
                    Toggle("I have freckles", isOn: $hasFreckles)
                }
                
                Section("Tanning Response") {
                    ForEach(TanningResponse.allCases, id: \.self) { response in
                        Button(action: { tanningResponse = response }) {
                            HStack {
                                Text(response.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if tanningResponse == response {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
    }
}

struct ProfileSummaryView: View {
    let fitzpatrickType: Int
    let eyeColor: EyeColor?
    let hairColor: HairColor?
    let hasFreckles: Bool
    let tanningResponse: TanningResponse?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Your Skin Profile")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding()
                
                VStack(alignment: .leading, spacing: 12) {
                    SummaryRow(label: "Skin Type", value: "Type \(romanNumeral(fitzpatrickType))")
                    
                    if let eye = eyeColor {
                        SummaryRow(label: "Eye Color", value: eye.displayName)
                    }
                    
                    if let hair = hairColor {
                        SummaryRow(label: "Hair Color", value: hair.displayName)
                    }
                    
                    if hasFreckles {
                        SummaryRow(label: "Freckles", value: "Yes")
                    }
                    
                    if let tanning = tanningResponse {
                        SummaryRow(label: "Tanning", value: tanning.displayName)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                Text("Your profile will be used to calculate personalized burn times and sun safety recommendations.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private func romanNumeral(_ number: Int) -> String {
        switch number {
        case 1: return "I"
        case 2: return "II"
        case 3: return "III"
        case 4: return "IV"
        case 5: return "V"
        case 6: return "VI"
        default: return String(number)
        }
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}