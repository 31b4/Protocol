import SwiftUI

extension Color {
    static let voidBackground = Color(red: 0.02, green: 0.02, blue: 0.04)
    static let glassBorder = Color.white.opacity(0.12)
    static let neonCyan = Color(red: 0.38, green: 0.97, blue: 1.0)
    static let neonAmber = Color(red: 1.0, green: 0.73, blue: 0.2)
    static let neonPink = Color(red: 1.0, green: 0.35, blue: 0.76)
}

extension View {
    func glassCard() -> some View {
        self
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.glassBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 18, x: 0, y: 12)
    }

    func glassPanel() -> some View {
        self
            .background(.ultraThinMaterial)
            .overlay(
                Rectangle()
                    .fill(Color.glassBorder)
                    .frame(height: 1),
                alignment: .top
            )
    }
}
