import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProtocolPlan.updatedAt, order: .reverse) private var protocols: [ProtocolPlan]
    @Query(sort: \ProtocolLog.createdAt, order: .reverse) private var logs: [ProtocolLog]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBackground.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        sectionHeader("Active Protocols", systemImage: "bolt.heart")

                        if activeProtocols.isEmpty {
                            emptyState
                        } else {
                            ForEach(activeProtocols) { plan in
                                ProtocolLogCard(
                                    plan: plan,
                                    currentVersion: plan.currentVersion,
                                    logs: logs,
                                    onToggle: { slot, items in
                                        toggleLog(for: plan, slot: slot, items: items)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Dashboard")
        }
    }

    private var activeProtocols: [ProtocolPlan] {
        protocols.filter { $0.isActive }
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.neonCyan.opacity(0.85))
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bolt.heart")
                .font(.system(size: 42, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.neonCyan)

            Text("No active protocols")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(.white)

            Text("Activate a protocol to see daily logging tasks.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .glassCard()
    }

    private func toggleLog(for plan: ProtocolPlan, slot: ProtocolSlot, items: [ProtocolItem]) {
        guard let version = plan.currentVersion else { return }
        let day = Date().startOfDay

        if let existing = logs.first(where: { $0.protocolID == plan.id && $0.slot == slot && Calendar.current.isDate($0.date, inSameDayAs: day) }) {
            modelContext.delete(existing)
            return
        }

        let log = ProtocolLog(
            protocolID: plan.id,
            versionID: version.id,
            date: day,
            slot: slot,
            status: .completed
        )
        let logItems = items.map {
            ProtocolLogItem(
                supplementName: $0.supplementName,
                amount: $0.amount,
                unit: $0.unit,
                log: log
            )
        }
        log.items = logItems
        modelContext.insert(log)
    }
}

private struct ProtocolLogCard: View {
    let plan: ProtocolPlan
    let currentVersion: ProtocolVersion?
    let logs: [ProtocolLog]
    let onToggle: (ProtocolSlot, [ProtocolItem]) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(plan.name)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)

                if let version = currentVersion {
                    Text(version.label)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
            }

            if let version = currentVersion {
                let morning = items(for: .morning, in: version)
                let day = items(for: .daytime, in: version)
                let night = items(for: .night, in: version)

                if !morning.isEmpty { slotRow(.morning, items: morning) }
                if !day.isEmpty { slotRow(.daytime, items: day) }
                if !night.isEmpty { slotRow(.night, items: night) }
            } else {
                Text("No version set")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .glassCard()
    }

    private func slotRow(_ slot: ProtocolSlot, items: [ProtocolItem]) -> some View {
        let isDone = isLogged(slot: slot)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon(for: slot))
                        .foregroundStyle(Color.neonCyan.opacity(0.85))
                    Text(slot.rawValue)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Button {
                    onToggle(slot, items)
                } label: {
                    Text(isDone ? "Taken" : "Mark Taken")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(isDone ? Color.neonCyan : .white)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                ForEach(items) { item in
                    Text("• \(item.supplementName) — \(item.amount, specifier: "%.2f") \(item.unit.rawValue)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
    }

    private func items(for slot: ProtocolSlot, in version: ProtocolVersion) -> [ProtocolItem] {
        (version.items ?? []).filter { $0.slot == slot }
    }

    private func isLogged(slot: ProtocolSlot) -> Bool {
        let day = Date().startOfDay
        return logs.contains { $0.protocolID == plan.id && $0.slot == slot && Calendar.current.isDate($0.date, inSameDayAs: day) }
    }

    private func icon(for slot: ProtocolSlot) -> String {
        switch slot {
        case .morning: return "sun.max.fill"
        case .daytime: return "sun.haze.fill"
        case .night: return "moon.stars.fill"
        }
    }
}

private extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}

#Preview {
    DashboardView()
}
