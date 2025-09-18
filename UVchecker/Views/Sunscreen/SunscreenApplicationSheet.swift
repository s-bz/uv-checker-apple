import SwiftUI

struct SunscreenApplicationSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSPF: SPFOption = .spf30
    @State private var selectedQuantity: ApplicationQuantity = .medium
    @State private var appliedAt: Date = Date()
    @State private var useCustomTime = false
    
    let onApply: (Int, ApplicationQuantity) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("SPF Level", selection: $selectedSPF) {
                        ForEach(SPFOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Sun Protection Factor")
                } footer: {
                    Text("Higher SPF provides more protection, but proper application is key.")
                }
                
                Section {
                    Picker("", selection: $selectedQuantity) {
                        ForEach(ApplicationQuantity.allCases, id: \.self) { quantity in
                            VStack(alignment: .leading) {
                                Text(quantity.displayName)
                                Text(quantity.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(quantity)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Quantity Applied")
                } footer: {
                    if selectedQuantity != .lots {
                        Label(selectedQuantity.recommendation, systemImage: "info.circle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Section {
                    Toggle("Set custom time", isOn: $useCustomTime)
                    
                    if useCustomTime {
                        DatePicker(
                            "Applied at",
                            selection: $appliedAt,
                            displayedComponents: .hourAndMinute
                        )
                    } else {
                        HStack {
                            Text("Applied at")
                            Spacer()
                            Text("Now")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Application Time")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(
                            title: "Effective SPF",
                            value: "\(Int(calculateEffectiveSPF()))",
                            color: effectiveSPFColor()
                        )
                        
                        InfoRow(
                            title: "Protection Level",
                            value: protectionLevelText(),
                            color: .secondary
                        )
                        
                        InfoRow(
                            title: "Reapply After",
                            value: "2 hours",
                            color: .secondary
                        )
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Protection Summary")
                }
            }
            .navigationTitle("Apply Sunscreen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply(selectedSPF.value, selectedQuantity)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func calculateEffectiveSPF() -> Double {
        let dose = selectedQuantity.doseInMgPerCm2
        return pow(Double(selectedSPF.value), dose / 2.0)
    }
    
    private func effectiveSPFColor() -> Color {
        let effective = calculateEffectiveSPF()
        let ratio = effective / Double(selectedSPF.value)
        
        if ratio >= 0.8 {
            return .green
        } else if ratio >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func protectionLevelText() -> String {
        let effective = calculateEffectiveSPF()
        
        if effective >= 30 {
            return "Excellent"
        } else if effective >= 15 {
            return "Good"
        } else if effective >= 5 {
            return "Moderate"
        } else {
            return "Limited"
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(color)
                .fontWeight(.medium)
        }
    }
}

// Extension to ApplicationQuantity for dose calculation
extension ApplicationQuantity {
    var doseInMgPerCm2: Double {
        switch self {
        case .low: return 0.5
        case .medium: return 1.0
        case .lots: return 2.0
        }
    }
}