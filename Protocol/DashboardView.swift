import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProtocolPlan.updatedAt, order: .reverse) private var protocols: [ProtocolPlan]
    @Query(sort: \ProtocolLog.createdAt, order: .reverse) private var logs: [ProtocolLog]
    @State private var selectedDate: Date = Date()
    @State private var showDatePicker = false
    @State private var showSettings = false
    @AppStorage("healthkit_enabled") private var healthKitEnabled = false

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
                                    },
                                    selectedDate: selectedDate
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .principal) {
                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            showDatePicker.toggle()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(dateTitle(for: selectedDate))
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                                .foregroundStyle(.white)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .overlay {
                if showDatePicker {
                    ZStack(alignment: .top) {
                        Color.black.opacity(0.45)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                    showDatePicker = false
                                }
                            }

                        LiquidGlassDatePicker(
                            selectedDate: $selectedDate,
                            onClose: {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                    showDatePicker = false
                                }
                            }
                        )
                        .padding(.top, 8)
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
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
        let day = selectedDate.startOfDay
        if let existing = logs.first(where: { $0.protocolID == plan.id && $0.slot == slot && Calendar.current.isDate($0.date, inSameDayAs: day) }) {
            if healthKitEnabled, let logItems = existing.items {
                Task { try? await HealthKitManager.shared.deleteSamples(items: logItems) }
            }
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
                supplementKey: $0.supplementKey,
                amount: $0.amount,
                unit: $0.unit,
                log: log
            )
        }
        log.items = logItems
        modelContext.insert(log)

        if healthKitEnabled {
            Task { try? await HealthKitManager.shared.saveNutritionSamples(items: logItems, date: day) }
        }
    }

    private func dateTitle(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today, \(formattedDate(date))"
        }
        if calendar.isDateInYesterday(date) {
            return "Yesterday, \(formattedDate(date))"
        }
        if calendar.isDateInTomorrow(date) {
            return "Tomorrow, \(formattedDate(date))"
        }
        return formattedDate(date)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
}

private struct ProtocolLogCard: View {
    let plan: ProtocolPlan
    let currentVersion: ProtocolVersion?
    let logs: [ProtocolLog]
    let onToggle: (ProtocolSlot, [ProtocolItem]) -> Void
    var selectedDate: Date = Date()

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
        let day = selectedDate.startOfDay
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

private struct LiquidGlassDatePicker: View {
    @Binding var selectedDate: Date
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            DatePicker(
                "",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .tint(Color.neonCyan)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, -6)
            .animation(.spring(response: 0.35, dampingFraction: 0.9), value: selectedDate)

            HStack {
                Button("Today") {
                    selectedDate = Date()
                    onClose()
                }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )

                Spacer()

                Button {
                    onClose()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                }
            }
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            }
        )
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 16)
    }
}

#Preview {
    DashboardView()
}
