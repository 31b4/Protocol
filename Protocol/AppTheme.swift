import SwiftUI

extension Color {
    static let voidBackground = Color(red: 0.05, green: 0.06, blue: 0.08)
    static let voidDeep = Color(red: 0.03, green: 0.04, blue: 0.06)
    static let surfaceTop = Color(red: 0.12, green: 0.14, blue: 0.18)
    static let surfaceBottom = Color(red: 0.08, green: 0.09, blue: 0.12)
    static let surfaceInsetTop = Color(red: 0.09, green: 0.1, blue: 0.13)
    static let surfaceInsetBottom = Color(red: 0.05, green: 0.06, blue: 0.08)
    static let glassBorder = Color.white.opacity(0.18)

    static let neonCyan = Color(red: 0.55, green: 0.85, blue: 1.0)
    static let neonAmber = Color(red: 0.95, green: 0.78, blue: 0.35)
    static let neonPink = Color(red: 0.95, green: 0.48, blue: 0.64)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.68)
    static let textTertiary = Color.white.opacity(0.45)
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.voidDeep, Color.voidBackground],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [Color.neonCyan.opacity(0.16), Color.clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 260
            )

            RadialGradient(
                colors: [Color.neonAmber.opacity(0.14), Color.clear],
                center: .bottomTrailing,
                startRadius: 40,
                endRadius: 260
            )
        }
    }
}

struct BevelSurface: View {
    let cornerRadius: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        shape
            .fill(
                LinearGradient(
                    colors: [Color.surfaceTop, Color.surfaceBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                shape
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.25), Color.white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .overlay(
                shape
                    .stroke(Color.black.opacity(0.55), lineWidth: 1)
                    .offset(x: 0, y: 1)
                    .blur(radius: 1)
            )
            .shadow(color: Color.black.opacity(0.55), radius: 20, x: 0, y: 14)
            .shadow(color: Color.white.opacity(0.06), radius: 6, x: -2, y: -2)
    }
}

struct BevelInsetSurface: View {
    let cornerRadius: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        shape
            .fill(
                LinearGradient(
                    colors: [Color.surfaceInsetTop, Color.surfaceInsetBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                shape.stroke(Color.black.opacity(0.6), lineWidth: 1)
            )
            .overlay(
                shape
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    .offset(x: 0, y: -1)
            )
    }
}

extension View {
    func glassCard() -> some View {
        self
            .padding(16)
            .background(BevelSurface(cornerRadius: 22))
    }

    func bevelInset(cornerRadius: CGFloat = 12) -> some View {
        self
            .background(BevelInsetSurface(cornerRadius: cornerRadius))
    }

    func glassPanel() -> some View {
        self
            .background(Color.voidBackground.opacity(0.9))
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 1),
                alignment: .top
            )
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    var tint: Color = .neonCyan

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    BevelInsetSurface(cornerRadius: 16)
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(tint.opacity(configuration.isPressed ? 0.28 : 0.2))
                }
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(BevelInsetSurface(cornerRadius: 14))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
