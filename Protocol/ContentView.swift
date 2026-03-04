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

            CheckInView()
                .tabItem {
                    Label("Check-in", systemImage: "square.and.pencil")
                }
        }
        .tint(Color.neonCyan)
        .toolbarBackground(Color.voidBackground.opacity(0.95), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
