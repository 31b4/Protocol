import SwiftUI
import SwiftData

struct ProtocolDetailView: View {
    let protocolPlan: ProtocolPlan

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProtocolLog.createdAt, order: .reverse) private var allLogs: [ProtocolLog]

    @State private var isEditing = false
    @State private var selectedVersion: ProtocolVersion?
    @State private var showVersionPicker = false

    // Expand states for slot sections
    @State private var morningExpanded = false
    @State private var dayExpanded = false
    @State private var nightExpanded = false

    // Per-slot notification state
    @State private var morningNotif = true
    @State private var dayNotif = true
    @State private var nightNotif = true
    @State private var morningTime = Date()
    @State private var daytimeTime = Date()
    @State private var nightTime = Date()

    var body: some View {
        let currentVersion = protocolPlan.currentVersion
        let displayVersion = selectedVersion ?? currentVersion

        ZStack {
            AppBackground()
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 20) {
                    summaryCard

                    // MARK: - Supplement Slots
                    if let version = displayVersion {
                        let morning = items(for: .morning, in: version)
                        let day = items(for: .daytime, in: version)
                        let night = items(for: .night, in: version)

                        if !morning.isEmpty {
                            collapsibleSlot(.morning, items: morning, expanded: $morningExpanded)
                        }
                        if !day.isEmpty {
                            collapsibleSlot(.daytime, items: day, expanded: $dayExpanded)
                        }
                        if !night.isEmpty {
                            collapsibleSlot(.night, items: night, expanded: $nightExpanded)
                        }
                    }

                    // MARK: - Weekly Adherence
                    if let version = displayVersion {
                        weeklyAdherenceSection(version: version)
                    }

                    // MARK: - Reminders
                    if let version = displayVersion {
                        remindersSection(version: version)
                    }

                    // MARK: - Version
                    versionsSection(currentVersion: currentVersion)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(protocolPlan.name)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(protocolPlan.name)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                    HStack(spacing: 8) {
                        if let version = displayVersion {
                            Text(version.label)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundStyle(Color.textSecondary)
                        }
                        Button {
                            protocolPlan.isActive.toggle()
                            protocolPlan.updatedAt = Date()
                            rescheduleAll()
                        } label: {
                            StatusPill(
                                text: protocolPlan.isActive ? "Active" : "Inactive",
                                tint: protocolPlan.isActive ? Color.neonCyan : Color.neonAmber
                            )
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { isEditing = true }
            }
        }
        .sheet(isPresented: $isEditing) {
            ProtocolEditorView(protocolPlan: protocolPlan)
        }
        .sheet(isPresented: $showVersionPicker) {
            ProtocolVersionPicker(
                versions: protocolPlan.sortedVersions,
                selectedVersion: $selectedVersion,
                currentVersion: currentVersion
            )
        }
        .onAppear {
            selectedVersion = currentVersion
            loadNotificationState()
        }
        .onChange(of: protocolPlan.updatedAt) { _, _ in
            selectedVersion = protocolPlan.currentVersion
            loadNotificationState()
        }
    }

    private var summaryCard: some View {
        let version = selectedVersion ?? protocolPlan.currentVersion
        let items = version?.items ?? []
        let slots = Set(items.map { $0.slot })

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(protocolPlan.name)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                    Text(version?.label ?? "No version")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Button("Edit") { isEditing = true }
                    .buttonStyle(SecondaryActionButtonStyle())
            }

            HStack(spacing: 12) {
                SummaryMetric(title: "Supplements", value: "\(items.count)")
                SummaryMetric(title: "Slots", value: "\(slots.count)")
                SummaryMetric(title: "Updated", value: protocolPlan.updatedAt.formatted(.dateTime.month().day()))
            }
        }
        .glassCard()
    }

    // MARK: - Collapsible Slot Section

    @ViewBuilder
    private func collapsibleSlot(_ slot: ProtocolSlot, items: [ProtocolItem], expanded: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header — always visible, tappable
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    expanded.wrappedValue.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: icon(for: slot))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.neonCyan)
                        .frame(width: 24)

                    Text(slot.rawValue)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Color.textPrimary)

                    Text("\(items.count)")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(BevelInsetSurface(cornerRadius: 10))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.textTertiary)
                        .rotationEffect(.degrees(expanded.wrappedValue ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            // Items — expandable
            if expanded.wrappedValue {
                VStack(spacing: 8) {
                    ForEach(items) { item in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.neonCyan.opacity(0.3))
                                .frame(width: 6, height: 6)

                            Text(item.supplementName)
                                .font(.system(.subheadline, design: .rounded).weight(.medium))
                                .foregroundStyle(Color.textPrimary)

                            Spacer()

                            Text("\(item.amount, specifier: "%g") \(item.unit.rawValue)")
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundStyle(Color.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(BevelInsetSurface(cornerRadius: 10))
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.top, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .glassCard()
    }

    // MARK: - Reminders Section

    @ViewBuilder
    private func remindersSection(version: ProtocolVersion) -> some View {
        let allItems = version.items ?? []
        let hasMorning = allItems.contains { $0.slot == .morning }
        let hasDay = allItems.contains { $0.slot == .daytime }
        let hasNight = allItems.contains { $0.slot == .night }

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.neonCyan)
                Text("Reminders")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.textTertiary)
            }

            VStack(spacing: 14) {
                if hasMorning {
                    slotReminderRow(slot: .morning, enabled: $morningNotif, time: $morningTime)
                }
                if hasDay {
                    slotReminderRow(slot: .daytime, enabled: $dayNotif, time: $daytimeTime)
                }
                if hasNight {
                    slotReminderRow(slot: .night, enabled: $nightNotif, time: $nightTime)
                }

                if hasMorning || hasDay || hasNight {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                        Text("You won't be notified for slots already taken or skipped.")
                            .font(.system(.caption2, design: .rounded))
                    }
                    .foregroundStyle(Color.textTertiary)
                    .padding(.top, 2)
                }
            }
            .glassCard()
        }
    }

    // MARK: - Weekly Adherence

    private func weeklyAdherenceSection(version: ProtocolVersion) -> some View {
        let days = adherenceDays(for: version)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.neonCyan)
                Text("Weekly Adherence")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.textTertiary)
            }

            HStack(spacing: 8) {
                ForEach(days) { day in
                    AdherenceDayPill(day: day)
                }
            }

            Text("Completed includes skipped slots.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Color.textTertiary)
        }
        .glassCard()
    }

    private func adherenceDays(for version: ProtocolVersion) -> [AdherenceDay] {
        let requiredSlots = ProtocolSlot.allCases.filter { slot in
            (version.items ?? []).contains { $0.slot == slot }
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let status = adherenceStatus(for: date, requiredSlots: requiredSlots)
            return AdherenceDay(date: date, status: status)
        }
    }

    private func adherenceStatus(for date: Date, requiredSlots: [ProtocolSlot]) -> AdherenceStatus {
        guard !requiredSlots.isEmpty else { return .none }

        let dayLogs = allLogs.filter {
            $0.protocolID == protocolPlan.id &&
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }

        let statuses = requiredSlots.map { slot in
            dayLogs.first(where: { $0.slot == slot })?.status
        }

        if statuses.contains(where: { $0 == .missed }) {
            return .missed
        }
        if statuses.allSatisfy({ $0 == .completed || $0 == .skipped }) {
            return .complete
        }
        if statuses.contains(where: { $0 == .completed || $0 == .skipped }) {
            return .partial
        }
        return .none
    }

    @ViewBuilder
    private func slotReminderRow(slot: ProtocolSlot, enabled: Binding<Bool>, time: Binding<Date>) -> some View {
        VStack(spacing: 10) {
            // Toggle row
            HStack(spacing: 10) {
                Image(systemName: icon(for: slot))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(enabled.wrappedValue ? Color.neonCyan : Color.textTertiary)
                    .frame(width: 22)

                Text(slot.rawValue)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(enabled.wrappedValue ? Color.textPrimary : Color.textTertiary)

                Spacer()

                Toggle("", isOn: enabled)
                    .labelsHidden()
                    .tint(Color.neonCyan)
                    .onChange(of: enabled.wrappedValue) { _, newValue in
                        NotificationManager.shared.setSlotEnabled(newValue, for: protocolPlan.id, slot: slot)
                        rescheduleAll()
                    }
            }

            Text(nextReminderLabel(for: slot, time: time.wrappedValue, enabled: enabled.wrappedValue))
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Time picker — only if enabled
            if enabled.wrappedValue {
                DatePicker(selection: time, displayedComponents: .hourAndMinute) {
                    Text("Notify at")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Color.textSecondary)
                }
                .onChange(of: time.wrappedValue) { _, newValue in
                    NotificationManager.shared.setTime(
                        NotificationManager.shared.components(from: newValue),
                        for: protocolPlan.id, slot: slot
                    )
                    rescheduleAll()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: enabled.wrappedValue)
    }

    // MARK: - Versions Section

    private func versionsSection(currentVersion: ProtocolVersion?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.neonCyan)
                Text("Versions")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.textTertiary)
            }

            Button {
                showVersionPicker = true
            } label: {
                HStack {
                    Text((selectedVersion ?? currentVersion)?.label ?? "Select")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .glassCard()
        }
    }

    // MARK: - Helpers

    private func loadNotificationState() {
        let mgr = NotificationManager.shared
        let id = protocolPlan.id
        morningNotif = mgr.slotEnabled(for: id, slot: .morning)
        dayNotif = mgr.slotEnabled(for: id, slot: .daytime)
        nightNotif = mgr.slotEnabled(for: id, slot: .night)
        morningTime = mgr.date(from: mgr.time(for: id, slot: .morning))
        daytimeTime = mgr.date(from: mgr.time(for: id, slot: .daytime))
        nightTime = mgr.date(from: mgr.time(for: id, slot: .night))
    }

    private func rescheduleAll() {
        let planDescriptor = FetchDescriptor<ProtocolPlan>()
        let plans = (try? modelContext.fetch(planDescriptor)) ?? []
        NotificationManager.shared.rescheduleAll(
            activeProtocols: plans.filter { $0.isActive },
            logs: Array(allLogs)
        )
    }

    private func items(for slot: ProtocolSlot, in version: ProtocolVersion) -> [ProtocolItem] {
        (version.items ?? []).filter { $0.slot == slot }
    }

    private func icon(for slot: ProtocolSlot) -> String {
        switch slot {
        case .morning: return "sun.max.fill"
        case .daytime: return "sun.haze.fill"
        case .night: return "moon.stars.fill"
        }
    }

    private func nextReminderLabel(for slot: ProtocolSlot, time: Date, enabled: Bool) -> String {
        guard enabled else { return "Reminders off" }
        guard let date = nextReminderDate(for: slot, time: time) else { return "Not scheduled" }

        let calendar = Calendar.current
        let day: String
        if calendar.isDateInToday(date) {
            day = "Today"
        } else if calendar.isDateInTomorrow(date) {
            day = "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            day = formatter.string(from: date)
        }

        return "Next: \(day) \(timeFormatter.string(from: date))"
    }

    private func nextReminderDate(for slot: ProtocolSlot, time: Date) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let comps = calendar.dateComponents([.hour, .minute], from: time)
        guard let hour = comps.hour, let minute = comps.minute else { return nil }

        let todayTrigger = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) ?? today
        let isLoggedToday = allLogs.contains { log in
            log.protocolID == protocolPlan.id &&
            log.slot == slot &&
            calendar.isDate(log.date, inSameDayAs: today) &&
            (log.status == .completed || log.status == .skipped || log.status == .missed)
        }

        if isLoggedToday || todayTrigger <= now {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: tomorrow)
        }

        return todayTrigger
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

private struct StatusPill: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.system(.caption2, design: .rounded).weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(BevelInsetSurface(cornerRadius: 10))
    }
}

private struct SummaryMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Color.textSecondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(BevelInsetSurface(cornerRadius: 12))
    }
}

private struct AdherenceDay: Identifiable {
    let id = UUID()
    let date: Date
    let status: AdherenceStatus

    var symbol: String {
        String(Self.formatter.string(from: date).prefix(1))
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "E"
        return formatter
    }()
}

private enum AdherenceStatus {
    case complete
    case partial
    case missed
    case none

    var color: Color {
        switch self {
        case .complete: return Color.neonCyan
        case .partial: return Color.neonAmber
        case .missed: return Color.neonPink
        case .none: return Color.textTertiary
        }
    }
}

private struct AdherenceDayPill: View {
    let day: AdherenceDay

    var body: some View {
        VStack(spacing: 6) {
            Text(day.symbol)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(Color.textSecondary)

            Circle()
                .fill(day.status.color)
                .frame(width: 10, height: 10)
        }
        .frame(width: 36)
        .padding(.vertical, 8)
        .background(BevelInsetSurface(cornerRadius: 12))
    }
}

private struct ProtocolVersionPicker: View {
    @Environment(\.dismiss) private var dismiss

    let versions: [ProtocolVersion]
    @Binding var selectedVersion: ProtocolVersion?
    let currentVersion: ProtocolVersion?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea()

                List {
                    ForEach(versions) { version in
                        Button {
                            selectedVersion = version
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(version.label)
                                        .font(.system(.headline, design: .rounded))
                                    Text(version.createdAt, style: .date)
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if version.id == (selectedVersion?.id ?? currentVersion?.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.neonCyan)
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Versions")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                if selectedVersion == nil {
                    selectedVersion = currentVersion
                }
            }
        }
    }
}
