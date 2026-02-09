import SwiftUI
import SwiftData

@main
struct ProtocolApp: App {
    private var sharedModelContainer: ModelContainer = {
        let schema = Schema([Biomarker.self, LabReport.self, ProtocolPlan.self, ProtocolVersion.self, ProtocolItem.self, ProtocolLog.self])
        let configuration = ModelConfiguration(
            cloudKitDatabase: .private("iCloud.com.31b4.Protocol")
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
