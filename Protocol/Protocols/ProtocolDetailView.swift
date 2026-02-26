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

        ScrollView {
            LazyVStack(spacing: 20) {

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
        .background(Color.voidBackground)
        .navigationTitle(protocolPlan.name)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(protocolPlan.name)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.white)
                    HStack(spacing: 8) {
                        if let version = displayVersion {
                            Text(version.label)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        Button(protocolPlan.isActive ? "Active" : "Inactive") {
                            protocolPlan.isActive.toggle()
                            protocolPlan.updatedAt = Date()
                            rescheduleAll()
                        }
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(protocolPlan.isActive ? Color.neonCyan : Color.neonAmber)
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
                        .foregroundStyle(.white)

                    Text("\(items.count)")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.08), in: Capsule())

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
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
                                .foregroundStyle(.white)

                            Spacer()

                            Text("\(item.amount, specifier: "%g") \(item.unit.rawValue)")
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundStyle(.white.opacity(0.55))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.06), in: Capsule())
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
                    .foregroundStyle(Color.neonCyan.opacity(0.85))
                Text("Reminders")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
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
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 2)
                }
            }
            .glassCard()
        }
    }

    @ViewBuilder
    private func slotReminderRow(slot: ProtocolSlot, enabled: Binding<Bool>, time: Binding<Date>) -> some View {
        VStack(spacing: 10) {
            // Toggle row
            HStack(spacing: 10) {
                Image(systemName: icon(for: slot))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(enabled.wrappedValue ? Color.neonCyan : .white.opacity(0.3))
                    .frame(width: 22)

                Text(slot.rawValue)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(enabled.wrappedValue ? .white : .white.opacity(0.4))

                Spacer()

                Toggle("", isOn: enabled)
                    .labelsHidden()
                    .tint(Color.neonCyan)
                    .onChange(of: enabled.wrappedValue) { _, newValue in
                        NotificationManager.shared.setSlotEnabled(newValue, for: protocolPlan.id, slot: slot)
                        rescheduleAll()
                    }
            }

            // Time picker — only if enabled
            if enabled.wrappedValue {
                DatePicker(selection: time, displayedComponents: .hourAndMinute) {
                    Text("Notify at")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
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
                    .foregroundStyle(Color.neonCyan.opacity(0.85))
                Text("Versions")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Button {
                showVersionPicker = true
            } label: {
                HStack {
                    Text((selectedVersion ?? currentVersion)?.label ?? "Select")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(.white.opacity(0.6))
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
}

private struct ProtocolVersionPicker: View {
    @Environment(\.dismiss) private var dismiss

    let versions: [ProtocolVersion]
    @Binding var selectedVersion: ProtocolVersion?
    let currentVersion: ProtocolVersion?

    var body: some View {
        NavigationStack {
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
