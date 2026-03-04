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
                AppBackground()
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        dailyOverviewCard
                        insightsCard

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

                        nextUpCard
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
                                .foregroundStyle(Color.textPrimary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.textSecondary)
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

    private var dailyOverviewCard: some View {
        let summary = dailySummary
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                ProgressRing(progress: summary.progress, size: 76, lineWidth: 10, tint: Color.neonCyan)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Daily Overview")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                    Text(summary.subtitle)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                SummaryPill(title: "Completed", value: summary.completed, color: Color.neonCyan)
                SummaryPill(title: "Pending", value: summary.pending, color: Color.textSecondary)
                SummaryPill(title: "Missed", value: summary.missed, color: Color.neonAmber)
                SummaryPill(title: "Skipped", value: summary.skipped, color: Color.neonPink)
            }

            HStack(spacing: 12) {
                SummaryMiniCard(title: "Streak", value: "\(streakCount) days", icon: "flame.fill", tint: Color.neonAmber)
                SummaryMiniCard(title: "Active", value: "\(activeProtocols.count) plans", icon: "bolt.heart.fill", tint: Color.neonCyan)
            }
        }
        .glassCard()
    }

    private var nextUpCard: some View {
        let items = upcomingSlots
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Next Up")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Image(systemName: "clock.badge.checkmark")
                    .foregroundStyle(Color.neonCyan)
            }

            if items.isEmpty {
                Text("You're all caught up.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            } else {
                ForEach(items) { item in
                    UpcomingSlotRow(item: item)
                }
            }
        }
        .glassCard()
    }

    private var insightsCard: some View {
        NavigationLink {
            InsightsView()
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Insights")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                    Text("Trends across adherence, biology, and check-ins.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.neonCyan)
            }
        }
        .buttonStyle(.plain)
        .glassCard()
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.neonCyan)
            Text(title.uppercased())
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(Color.textTertiary)
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
                .foregroundStyle(Color.textPrimary)

            Text("Activate a protocol to see daily logging tasks.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .glassCard()
    }

    private var dailySummary: DailySummary {
        summary(for: selectedDate)
    }

    private var streakCount: Int {
        var streak = 0
        var currentDate = selectedDate.startOfDay

        while streak < 365 {
            let summary = summary(for: currentDate)
            if summary.total == 0 { break }
            if summary.missed > 0 || summary.pending > 0 { break }
            streak += 1

            guard let previous = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previous
        }

        return streak
    }

    private func summary(for date: Date) -> DailySummary {
        let requirements = requiredSlots()
        guard !requirements.isEmpty else {
            return DailySummary(total: 0, completed: 0, skipped: 0, missed: 0, pending: 0)
        }

        let day = date.startOfDay
        let activeIDs = Set(activeProtocols.map { $0.id })
        let dayLogs = logs.filter { activeIDs.contains($0.protocolID) && Calendar.current.isDate($0.date, inSameDayAs: day) }

        var completed = 0
        var skipped = 0
        var missed = 0
        var pending = 0

        for requirement in requirements {
            if let log = dayLogs.first(where: { $0.protocolID == requirement.planID && $0.slot == requirement.slot }) {
                switch log.status {
                case .completed:
                    completed += 1
                case .skipped:
                    skipped += 1
                case .missed:
                    missed += 1
                case .undecided:
                    pending += 1
                }
            } else {
                pending += 1
            }
        }

        return DailySummary(
            total: requirements.count,
            completed: completed,
            skipped: skipped,
            missed: missed,
            pending: pending
        )
    }

    private func requiredSlots() -> [SlotRequirement] {
        var requirements: [SlotRequirement] = []
        for plan in activeProtocols {
            guard let version = plan.currentVersion else { continue }
            for slot in ProtocolSlot.allCases {
                if (version.items ?? []).contains(where: { $0.slot == slot }) {
                    requirements.append(SlotRequirement(planID: plan.id, slot: slot))
                }
            }
        }
        return requirements
    }

    private var upcomingSlots: [UpcomingSlot] {
        let now = Date()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today

        var items: [UpcomingSlot] = []

        for plan in activeProtocols {
            guard let version = plan.currentVersion else { continue }
            let allItems = version.items ?? []

            for slot in ProtocolSlot.allCases {
                guard allItems.contains(where: { $0.slot == slot }) else { continue }
                guard NotificationManager.shared.slotEnabled(for: plan.id, slot: slot) else { continue }

                let time = NotificationManager.shared.time(for: plan.id, slot: slot)
                let hour = time.hour ?? 8
                let minute = time.minute ?? 0

                let todayTrigger = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) ?? today
                let isLoggedToday = logs.contains { log in
                    log.protocolID == plan.id &&
                    log.slot == slot &&
                    calendar.isDate(log.date, inSameDayAs: today) &&
                    (log.status == .completed || log.status == .skipped || log.status == .missed)
                }

                let nextDate: Date
                if isLoggedToday || todayTrigger <= now {
                    nextDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: tomorrow) ?? tomorrow
                } else {
                    nextDate = todayTrigger
                }

                items.append(UpcomingSlot(planName: plan.name, slot: slot, date: nextDate))
            }
        }

        return items.sorted { $0.date < $1.date }.prefix(3).map { $0 }
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

private struct SlotRequirement: Hashable {
    let planID: UUID
    let slot: ProtocolSlot
}

private struct UpcomingSlot: Identifiable {
    let id = UUID()
    let planName: String
    let slot: ProtocolSlot
    let date: Date
}

private struct DailySummary {
    let total: Int
    let completed: Int
    let skipped: Int
    let missed: Int
    let pending: Int

    var resolved: Int {
        completed + skipped
    }

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(resolved) / Double(total)
    }

    var subtitle: String {
        guard total > 0 else { return "No scheduled slots" }
        return "\(resolved) of \(total) resolved"
    }
}

private struct UpcomingSlotRow: View {
    let item: UpcomingSlot

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: item.date)
    }

    private var dayText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(item.date) {
            return "Today"
        }
        if calendar.isDateInTomorrow(item.date) {
            return "Tomorrow"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: item.date)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: slotIcon(item.slot))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.neonCyan)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.planName)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("\(dayText) · \(item.slot.rawValue)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            Text(timeText)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(BevelInsetSurface(cornerRadius: 12))
        }
    }

    private func slotIcon(_ slot: ProtocolSlot) -> String {
        switch slot {
        case .morning: return "sun.max.fill"
        case .daytime: return "sun.haze.fill"
        case .night: return "moon.stars.fill"
        }
    }
}

private struct ProgressRing: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(progress, 0.001))
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text("\(Int(progress * 100))%")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.textPrimary)
        }
        .frame(width: size, height: size)
        .animation(.easeOut(duration: 0.2), value: progress)
    }
}

private struct SummaryPill: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Color.textSecondary)

            Spacer()

            Text("\(value)")
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(BevelInsetSurface(cornerRadius: 14))
    }
}

private struct SummaryMiniCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
                Text(value)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(BevelInsetSurface(cornerRadius: 16))
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
                    .foregroundStyle(Color.textPrimary)

                if let version = currentVersion {
                    Text(version.label)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.textSecondary)
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
                    .foregroundStyle(Color.textSecondary)
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
                        .foregroundStyle(Color.neonCyan)
                    Text(slot.rawValue)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.textSecondary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.textTertiary)
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
                            .foregroundStyle(Color.textSecondary)
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
                    ZStack {
                        BevelInsetSurface(cornerRadius: 10)
                        if isSelected {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(accentColor.opacity(0.22))
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(isSelected ? 0.16 : 0.08), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        if !isSelected { return Color.textTertiary }
        switch label {
        case "✕": return Color.neonAmber
        case "-": return Color.textPrimary
        case "✓": return Color.neonCyan
        default: return Color.textPrimary
        }
    }

    private var accentColor: Color {
        switch label {
        case "✕": return Color.neonAmber
        case "-": return Color.white
        case "✓": return Color.neonCyan
        default: return Color.white
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
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(BevelInsetSurface(cornerRadius: 18))

                Spacer()

                Button {
                    onClose()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                        .padding(10)
                        .background(BevelInsetSurface(cornerRadius: 18))
                }
            }
        }
        .padding(20)
        .background(BevelSurface(cornerRadius: 24))
    }
}

#Preview {
    DashboardView()
}
