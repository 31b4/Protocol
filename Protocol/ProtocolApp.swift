import SwiftUI
import SwiftData

@main
struct ProtocolApp: App {
    private var sharedModelContainer: ModelContainer = {
        let schema = Schema(versionedSchema: ProtocolSchemaV3.self)
        let configuration = ModelConfiguration(
            cloudKitDatabase: .private("iCloud.com.31b4.Protocol")
        )

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: ProtocolMigrationPlan.self,
                configurations: [configuration]
            )
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
