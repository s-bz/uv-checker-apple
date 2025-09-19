import SwiftUI

struct ReleaseNotesView: View {
    @Environment(\.dismiss) private var dismiss
    
    struct ReleaseNote: Identifiable {
        let id = UUID()
        let version: String
        let date: String
        let features: [String]
        let fixes: [String]
        let improvements: [String]
    }
    
    private let releaseNotes: [ReleaseNote] = [
        ReleaseNote(
            version: "1.0.0",
            date: "September 2025",
            features: [
                "Real-time UV index monitoring",
                "Personalized burn time calculations",
                "Sunscreen application tracking",
                "24-hour UV forecast timeline",
                "Home screen widget",
                "Skin profile customization"
            ],
            fixes: [],
            improvements: []
        )
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(releaseNotes) { release in
                        ReleaseNoteCard(release: release, isLatest: release.id == releaseNotes.first?.id)
                    }
                }
                .padding()
            }
            .navigationTitle("Release Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ReleaseNoteCard: View {
    let release: ReleaseNotesView.ReleaseNote
    let isLatest: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Version header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Version \(release.version)")
                        .font(.headline)
                    Text(release.date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isLatest {
                    Text("Latest")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
            
            // Features
            if !release.features.isEmpty {
                ReleaseSection(title: "What's New", items: release.features, icon: "sparkles", color: .orange)
            }
            
            // Improvements
            if !release.improvements.isEmpty {
                ReleaseSection(title: "Improvements", items: release.improvements, icon: "arrow.up.circle.fill", color: .blue)
            }
            
            // Fixes
            if !release.fixes.isEmpty {
                ReleaseSection(title: "Bug Fixes", items: release.fixes, icon: "checkmark.circle.fill", color: .green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

struct ReleaseSection: View {
    let title: String
    let items: [String]
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(color)
                        .frame(width: 16)
                    Text(item)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    ReleaseNotesView()
}