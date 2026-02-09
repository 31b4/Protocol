import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "sparkle")
                }

            BiologyView()
                .tabItem {
                    Label("Biology", systemImage: "waveform.path.ecg")
                }

            ProtocolsView()
                .tabItem {
                    Label("Protocols", systemImage: "bolt.heart")
                }
        }
        .tint(Color.neonCyan)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .preferredColorScheme(.dark)
    }
}

private struct DashboardView: View {
    var body: some View {
        ZStack {
            Color.voidBackground.ignoresSafeArea()
            Text("Dashboard")
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

#Preview {
    ContentView()
}
