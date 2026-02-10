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

#Preview {
    ContentView()
}
