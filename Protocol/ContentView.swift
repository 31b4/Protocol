import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "flask.fill")
                .imageScale(.large)
                .foregroundStyle(.cyan)
            Text("Protocol v1.0")
        }
        .padding()
        .preferredColorScheme(.dark) // Force dark mode for that "Glass Terminal" look
    }
}

#Preview {
    ContentView()
}
