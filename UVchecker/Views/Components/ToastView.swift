import SwiftUI

struct ToastView: View {
    let message: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.85))
        .cornerRadius(25)
        .shadow(radius: 10)
        .padding(.horizontal)
        .padding(.bottom, 50)
    }
}