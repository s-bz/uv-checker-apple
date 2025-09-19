//
//  UVInfoModal.swift
//  UVSense
//
//  Modal showing detailed UV index information and safety guidelines
//

import SwiftUI

struct UVInfoModal: View {
    @Binding var isPresented: Bool
    let currentUVIndex: Double
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current UV Status
                    VStack(spacing: 10) {
                        Text("Your Current UV Level")
                            .font(.headline)
                        
                        ZStack {
                            Circle()
                                .fill(uvIndexColor(for: currentUVIndex))
                                .frame(width: 100, height: 100)
                            
                            VStack(spacing: 2) {
                                Text("\(Int(currentUVIndex))")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(uvIndexLevel(for: currentUVIndex))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Text(currentUVDescription(for: currentUVIndex))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                    
                    // UV Index Scale
                    VStack(spacing: 16) {
                        Text("Understanding UV Levels")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ForEach(uvIndexRanges, id: \.range) { info in
                            HStack(alignment: .top, spacing: 12) {
                                // Color indicator
                                ZStack {
                                    Circle()
                                        .fill(info.color)
                                        .frame(width: 60, height: 60)
                                    
                                    VStack(spacing: 0) {
                                        Text(info.range)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("UV")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                // Description
                                Text(info.description)
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("UV Safety Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func currentUVDescription(for index: Double) -> String {
        switch index {
        case 0..<3:
            return "Great conditions! Enjoy the outdoors safely with minimal sun protection."
        case 3..<6:
            return "Stay protected during midday. Consider sunscreen and a hat."
        case 6..<8:
            return "Seek shade between 10am-4pm. Sunscreen, hat, and sunglasses recommended."
        case 8..<11:
            return "Minimize sun exposure. Use SPF 30+, protective clothing, and stay in shade."
        default:
            return "Extreme conditions! Avoid outdoor activities during peak hours if possible."
        }
    }
}

// UV Index data structure
struct UVIndexInfo {
    let range: String
    let color: Color
    let description: String
}

let uvIndexRanges: [UVIndexInfo] = [
    UVIndexInfo(
        range: "0-2",
        color: Color.green,
        description: "Safe for most people. Enjoy outdoor activities with minimal protection needed."
    ),
    UVIndexInfo(
        range: "3-5",
        color: Color.yellow,
        description: "Moderate risk. Fair skin may burn in 20 minutes. Wear sunscreen and a hat during midday."
    ),
    UVIndexInfo(
        range: "6-7",
        color: Color.orange,
        description: "High risk. Protection required. Seek shade 10am-4pm, use SPF 15+ sunscreen."
    ),
    UVIndexInfo(
        range: "8-10",
        color: Color.red,
        description: "Very high risk. Burns can occur in 10 minutes. Cover up, use SPF 30+, limit exposure."
    ),
    UVIndexInfo(
        range: "10+",
        color: Color.purple,
        description: "Extreme risk. Take all precautions. Avoid sun 10am-4pm, stay indoors when possible."
    )
]

// Helper functions
func uvIndexColor(for index: Double) -> Color {
    switch index {
    case 0..<3: return .green
    case 3..<6: return .yellow
    case 6..<8: return .orange
    case 8..<11: return .red
    default: return .purple
    }
}

func uvIndexLevel(for index: Double) -> String {
    switch index {
    case 0..<3: return "Low"
    case 3..<6: return "Moderate"
    case 6..<8: return "High"
    case 8..<11: return "Very High"
    default: return "Extreme"
    }
}