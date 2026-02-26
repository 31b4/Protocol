import SwiftUI
import SwiftData

@main
struct ProtocolApp: App {
    private var sharedModelContainer: ModelContainer = {
        let schema = Schema(versionedSchema: ProtocolSchemaV7.self)
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

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupNotifications()
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                rescheduleNotificationsFromContext()
            }
        }
    }

    private func setupNotifications() {
        Task {
            _ = await NotificationManager.shared.requestAuthorization()
            rescheduleNotificationsFromContext()
        }
    }

    private func rescheduleNotificationsFromContext() {
        let context = sharedModelContainer.mainContext
        let planDescriptor = FetchDescriptor<ProtocolPlan>()
        let logDescriptor = FetchDescriptor<ProtocolLog>()

        let plans = (try? context.fetch(planDescriptor)) ?? []
        let logs = (try? context.fetch(logDescriptor)) ?? []

        let activePlans = plans.filter { $0.isActive }
        NotificationManager.shared.rescheduleAll(activeProtocols: activePlans, logs: logs)
    }
}
