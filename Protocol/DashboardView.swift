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
                                    onStatusChange: { slot, items, status in
                                        setLogStatus(for: plan, slot: slot, items: items, status: status)
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

    private func setLogStatus(for plan: ProtocolPlan, slot: ProtocolSlot, items: [ProtocolItem], status: ProtocolLogStatus) {
        guard let version = plan.currentVersion else { return }
        let day = selectedDate.startOfDay
        if let existing = logs.first(where: { $0.protocolID == plan.id && $0.slot == slot && Calendar.current.isDate($0.date, inSameDayAs: day) }) {
            if healthKitEnabled, let logItems = existing.items, existing.status == .completed, status != .completed {
                Task { try? await HealthKitManager.shared.deleteSamples(items: logItems) }
            }
            existing.status = status
            if healthKitEnabled, status == .completed, let logItems = existing.items {
                Task { try? await HealthKitManager.shared.saveNutritionSamples(items: logItems, date: day) }
            }
            rescheduleNotificationsAfterLog()
            return
        }

        let log = ProtocolLog(
            protocolID: plan.id,
            versionID: version.id,
            date: day,
            slot: slot,
            status: status
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

        if healthKitEnabled, status == .completed {
            Task { try? await HealthKitManager.shared.saveNutritionSamples(items: logItems, date: day) }
        }

        rescheduleNotificationsAfterLog()
    }

    private func rescheduleNotificationsAfterLog() {
        NotificationManager.shared.rescheduleAll(
            activeProtocols: activeProtocols,
            logs: Array(logs)
        )
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
    let onStatusChange: (ProtocolSlot, [ProtocolItem], ProtocolLogStatus) -> Void
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
        let status = loggedStatus(slot: slot)

        return ExpandableSlotRow(
            slot: slot,
            items: items,
            status: status,
            onStatusChange: { newStatus in
                onStatusChange(slot, items, newStatus)
            }
        )
    }

    private func items(for slot: ProtocolSlot, in version: ProtocolVersion) -> [ProtocolItem] {
        (version.items ?? []).filter { $0.slot == slot }
    }

    private func loggedStatus(slot: ProtocolSlot) -> ProtocolLogStatus {
        let day = selectedDate.startOfDay
        if let log = logs.first(where: { $0.protocolID == plan.id && $0.slot == slot && Calendar.current.isDate($0.date, inSameDayAs: day) }) {
            return log.status
        }
        return .undecided
    }

    private func icon(for slot: ProtocolSlot) -> String {
        switch slot {
        case .morning: return "sun.max.fill"
        case .daytime: return "sun.haze.fill"
        case .night: return "moon.stars.fill"
        }
    }

    @ViewBuilder
    private func statusSelector(status: ProtocolLogStatus, slot: ProtocolSlot, items: [ProtocolItem]) -> some View {
        HStack(spacing: 8) {
            StatusButton(label: "✕", isSelected: status == .missed) {
                onStatusChange(slot, items, .missed)
            }
            StatusButton(label: "-", isSelected: status == .undecided) {
                onStatusChange(slot, items, .undecided)
            }
            StatusButton(label: "✓", isSelected: status == .completed) {
                onStatusChange(slot, items, .completed)
            }
        }
        .animation(.easeOut(duration: 0.18), value: status)
    }
}

private struct ExpandableSlotRow: View {
    let slot: ProtocolSlot
    let items: [ProtocolItem]
    let status: ProtocolLogStatus
    let onStatusChange: (ProtocolLogStatus) -> Void

    @State private var isExpanded = false
    @State private var showConfirm = false
    @State private var pendingStatus: ProtocolLogStatus?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon(for: slot))
                        .foregroundStyle(Color.neonCyan.opacity(0.85))
                    Text(slot.rawValue)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                Spacer()
                statusSelector(status: status, onStatusChange: onStatusChange)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.18)) {
                    isExpanded.toggle()
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(items) { item in
                        Text("• \(item.supplementName) — \(item.amount, specifier: "%.2f") \(item.unit.rawValue)")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func icon(for slot: ProtocolSlot) -> String {
        switch slot {
        case .morning: return "sun.max.fill"
        case .daytime: return "sun.haze.fill"
        case .night: return "moon.stars.fill"
        }
    }

    @ViewBuilder
    private func statusSelector(status: ProtocolLogStatus, onStatusChange: @escaping (ProtocolLogStatus) -> Void) -> some View {
        HStack(spacing: 8) {
            StatusButton(label: "✕", isSelected: status == .missed) {
                handleStatusChange(.missed)
            }
            StatusButton(label: "-", isSelected: status == .undecided) {
                handleStatusChange(.undecided)
            }
            StatusButton(label: "✓", isSelected: status == .completed) {
                handleStatusChange(.completed)
            }
        }
        .animation(.easeOut(duration: 0.18), value: status)
        .alert("Change status?", isPresented: $showConfirm) {
            Button("Change", role: .destructive) {
                if let pendingStatus {
                    onStatusChange(pendingStatus)
                }
                pendingStatus = nil
            }
            Button("Cancel", role: .cancel) {
                pendingStatus = nil
            }
        } message: {
            Text("This was marked as done. Are you sure you want to change it?")
        }
    }

    private func handleStatusChange(_ newStatus: ProtocolLogStatus) {
        if (status == .completed || status == .missed) && newStatus == .undecided {
            onStatusChange(newStatus)
            return
        }
        if (status == .completed && newStatus != .completed) || (status == .missed && newStatus != .missed) {
            pendingStatus = newStatus
            showConfirm = true
            return
        }
        onStatusChange(newStatus)
    }
}

private struct StatusButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(foregroundColor)
                .frame(width: 36, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(backgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        if !isSelected { return .white.opacity(0.6) }
        switch label {
        case "✕": return Color.neonAmber
        case "-": return Color.white.opacity(0.8)
        case "✓": return Color.neonCyan
        default: return .white
        }
    }

    private var backgroundColor: Color {
        if !isSelected { return Color.glassBorder.opacity(0.4) }
        switch label {
        case "✕": return Color.neonAmber.opacity(0.25)
        case "-": return Color.white.opacity(0.12)
        case "✓": return Color.neonCyan.opacity(0.25)
        default: return Color.glassBorder.opacity(0.4)
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
