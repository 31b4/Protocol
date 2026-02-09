import SwiftUI
import SwiftData

struct ProtocolsView: View {
    @Query(sort: \ProtocolPlan.updatedAt, order: .reverse) private var protocols: [ProtocolPlan]
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBackground.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        Button {
                            isCreating = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                Text("Create Protocol")
                                    .font(.system(.headline, design: .rounded).weight(.semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                        }
                        .glassCard()

                        if protocols.isEmpty {
                            emptyState
                        } else {
                            ForEach(protocols) { plan in
                                NavigationLink {
                                    ProtocolDetailView(protocolPlan: plan)
                                } label: {
                                    ProtocolCard(plan: plan)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Protocols")
            .sheet(isPresented: $isCreating) {
                ProtocolEditorView(protocolPlan: nil)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "capsule")
                .font(.system(size: 42, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.neonCyan)

            Text("No protocols yet")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(.white)

            Text("Create your first supplement protocol to track daily routines.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .glassCard()
    }
}

private struct ProtocolCard: View {
    let plan: ProtocolPlan

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(plan.name)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)

                Text("Updated \(plan.updatedAt, style: .date)")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            if let current = plan.versions?.sorted(by: { $0.createdAt > $1.createdAt }).first {
                Text(current.label)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.neonCyan)
            }
        }
        .glassCard()
    }
}

struct ProtocolDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let protocolPlan: ProtocolPlan

    @Query private var logs: [ProtocolLog]

    @State private var isEditing = false
    @State private var selectedVersion: ProtocolVersion?

    init(protocolPlan: ProtocolPlan) {
        self.protocolPlan = protocolPlan
        let protocolID = protocolPlan.id
        _logs = Query(filter: #Predicate<ProtocolLog> { $0.protocolID == protocolID })
    }

    var body: some View {
        let currentVersion = protocolPlan.versions?.sorted(by: { $0.createdAt > $1.createdAt }).first
        let versionItems = currentVersion?.items ?? []

        ScrollView {
            LazyVStack(spacing: 16) {
                headerCard(currentVersion: currentVersion)

                if let currentVersion {
                    slotSection(.morning, items: items(for: .morning, in: currentVersion))
                    slotSection(.daytime, items: items(for: .daytime, in: currentVersion))
                    slotSection(.night, items: items(for: .night, in: currentVersion))

                    logSection(for: currentVersion)
                }

                versionsSection
                calendarSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.voidBackground)
        .navigationTitle(protocolPlan.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { isEditing = true }
            }
        }
        .sheet(isPresented: $isEditing) {
            ProtocolEditorView(protocolPlan: protocolPlan)
        }
        .sheet(item: $selectedVersion) { version in
            ProtocolVersionDetail(version: version)
        }
    }

    private func headerCard(currentVersion: ProtocolVersion?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(protocolPlan.name)
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .foregroundStyle(.white)

            if let currentVersion {
                Text("Current version \(currentVersion.label)")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .glassCard()
    }

    private func slotSection(_ slot: ProtocolSlot, items: [ProtocolItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(slot.rawValue)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))

            if items.isEmpty {
                Text("No supplements scheduled")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                ForEach(items) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.supplementName)
                                .font(.system(.headline, design: .rounded))
                                .foregroundStyle(.white)
                            Text("\(item.amount, specifier: "%.2f") \(item.unit.rawValue)")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        Spacer()
                    }
                    .glassCard()
                }
            }
        }
    }

    private func logSection(for version: ProtocolVersion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))

            ForEach(ProtocolSlot.allCases) { slot in
                LogRow(
                    slot: slot,
                    status: logStatus(for: slot),
                    onChange: { newStatus in
                        saveLog(for: slot, status: newStatus, version: version)
                    }
                )
            }
        }
        .glassCard()
    }

    private var versionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Versions")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))

            if let versions = protocolPlan.versions?.sorted(by: { $0.createdAt > $1.createdAt }) {
                ForEach(versions) { version in
                    Button {
                        selectedVersion = version
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(version.label)
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(.white)
                                Text(version.createdAt, style: .date)
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            Spacer()
                            Text("View")
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundStyle(Color.neonCyan)
                        }
                    }
                    .buttonStyle(.plain)
                    .glassCard()
                }
            }
        }
    }

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calendar")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
            ProtocolCalendarView(protocolID: protocolPlan.id, logs: logs)
        }
        .glassCard()
    }

    private func items(for slot: ProtocolSlot, in version: ProtocolVersion) -> [ProtocolItem] {
        (version.items ?? []).filter { $0.slot == slot }
    }

    private func logStatus(for slot: ProtocolSlot) -> ProtocolLogStatus? {
        let day = Date().startOfDay
        return logs.first { $0.slot == slot && Calendar.current.isDate($0.date, inSameDayAs: day) }?.status
    }

    private func saveLog(for slot: ProtocolSlot, status: ProtocolLogStatus?, version: ProtocolVersion) {
        let day = Date().startOfDay
        if let existing = logs.first(where: { $0.slot == slot && Calendar.current.isDate($0.date, inSameDayAs: day) }) {
            if let status {
                existing.status = status
            } else {
                modelContext.delete(existing)
            }
        } else if let status {
            let log = ProtocolLog(
                protocolID: protocolPlan.id,
                versionID: version.id,
                date: day,
                slot: slot,
                status: status
            )
            modelContext.insert(log)
        }
    }
}

private struct LogRow: View {
    let slot: ProtocolSlot
    let status: ProtocolLogStatus?
    let onChange: (ProtocolLogStatus?) -> Void

    var body: some View {
        HStack {
            Text(slot.rawValue)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Menu {
                Button("Completed") { onChange(.completed) }
                Button("Missed") { onChange(.missed) }
                Button("Skipped") { onChange(.skipped) }
                Button("Clear") { onChange(nil) }
            } label: {
                Text(status?.rawValue ?? "Unset")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.neonCyan)
            }
        }
    }
}

struct ProtocolVersionDetail: View {
    @Environment(\.dismiss) private var dismiss
    let version: ProtocolVersion

    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBackground.ignoresSafeArea()
                List {
                    ForEach(ProtocolSlot.allCases) { slot in
                        Section(slot.rawValue) {
                            let items = (version.items ?? []).filter { $0.slot == slot }
                            if items.isEmpty {
                                Text("No supplements")
                                    .foregroundStyle(.white.opacity(0.6))
                            } else {
                                ForEach(items) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.supplementName)
                                                .font(.system(.headline, design: .rounded))
                                                .foregroundStyle(.white)
                                            Text("\(item.amount, specifier: "%.2f") \(item.unit.rawValue)")
                                                .font(.system(.subheadline, design: .rounded))
                                                .foregroundStyle(.white.opacity(0.7))
                                        }
                                        Spacer()
                                    }
                                    .listRowBackground(Color.clear)
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(version.label)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct ProtocolEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let protocolPlan: ProtocolPlan?

    @State private var name: String = ""
    @State private var morningItems: [ProtocolDraftItem] = []
    @State private var dayItems: [ProtocolDraftItem] = []
    @State private var nightItems: [ProtocolDraftItem] = []
    @State private var versionBump: VersionBump = .keep

    @State private var showCatalogSlot: ProtocolSlot?

    var body: some View {
        NavigationStack {
            Form {
                Section("Protocol") {
                    TextField("Name", text: $name)
                }

                if protocolPlan != nil {
                    Section("Versioning") {
                        Picker("Save as", selection: $versionBump) {
                            ForEach(VersionBump.allCases) { bump in
                                Text(bump.title).tag(bump)
                            }
                        }
                    }
                }

                slotEditorSection(.morning, items: $morningItems)
                slotEditorSection(.daytime, items: $dayItems)
                slotEditorSection(.night, items: $nightItems)
            }
            .navigationTitle(protocolPlan == nil ? "New Protocol" : "Edit Protocol")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .sheet(item: $showCatalogSlot) { slot in
                SupplementPicker(slot: slot, onSelect: { template in
                    addItem(from: template, to: slot)
                })
            }
            .onAppear {
                if let protocolPlan {
                    name = protocolPlan.name
                    if let current = protocolPlan.versions?.sorted(by: { $0.createdAt > $1.createdAt }).first {
                        let grouped = Dictionary(grouping: current.items ?? [], by: { $0.slot })
                        morningItems = (grouped[.morning] ?? []).map(ProtocolDraftItem.init)
                        dayItems = (grouped[.daytime] ?? []).map(ProtocolDraftItem.init)
                        nightItems = (grouped[.night] ?? []).map(ProtocolDraftItem.init)
                    }
                }
            }
        }
    }

    private func slotEditorSection(_ slot: ProtocolSlot, items: Binding<[ProtocolDraftItem]>) -> some View {
        Section(slot.rawValue) {
            if items.wrappedValue.isEmpty {
                Text("No supplements")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items.wrappedValue.indices, id: \.self) { index in
                    ProtocolDraftRow(item: Binding(
                        get: { items.wrappedValue[index] },
                        set: { items.wrappedValue[index] = $0 }
                    ))
                }
                .onDelete { offsets in
                    items.wrappedValue.remove(atOffsets: offsets)
                }
            }

            Button("Add \(slot.rawValue)") {
                showCatalogSlot = slot
            }
        }
    }

    private func addItem(from template: SupplementTemplate, to slot: ProtocolSlot) {
        let draft = ProtocolDraftItem(
            slot: slot,
            supplementName: template.name,
            supplementKey: template.id,
            amount: 1,
            unit: template.defaultUnit
        )
        switch slot {
        case .morning:
            morningItems.append(draft)
        case .daytime:
            dayItems.append(draft)
        case .night:
            nightItems.append(draft)
        }
    }

    private func save() {
        let allItems = morningItems + dayItems + nightItems
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !allItems.isEmpty else { return }

        if let protocolPlan {
            protocolPlan.name = name
            protocolPlan.updatedAt = Date()

            guard let current = protocolPlan.versions?.sorted(by: { $0.createdAt > $1.createdAt }).first else {
                let newVersion = ProtocolVersion(major: 1, minor: 0, plan: protocolPlan)
                let items = allItems.map { $0.toModel(version: newVersion) }
                newVersion.items = items
                protocolPlan.versions = [newVersion]
                dismiss()
                return
            }

            switch versionBump {
            case .keep:
                if let existing = current.items {
                    for item in existing {
                        modelContext.delete(item)
                    }
                }
                let items = allItems.map { $0.toModel(version: current) }
                current.items = items
            case .patch:
                let newVersion = ProtocolVersion(major: current.major, minor: current.minor + 1, plan: protocolPlan)
                let items = allItems.map { $0.toModel(version: newVersion) }
                newVersion.items = items
                protocolPlan.versions = (protocolPlan.versions ?? []) + [newVersion]
            case .major:
                let newVersion = ProtocolVersion(major: current.major + 1, minor: 0, plan: protocolPlan)
                let items = allItems.map { $0.toModel(version: newVersion) }
                newVersion.items = items
                protocolPlan.versions = (protocolPlan.versions ?? []) + [newVersion]
            }
        } else {
            let plan = ProtocolPlan(name: name)
            let version = ProtocolVersion(major: 1, minor: 0, plan: plan)
            let items = allItems.map { $0.toModel(version: version) }
            version.items = items
            plan.versions = [version]
            modelContext.insert(plan)
        }

        dismiss()
    }
}

private struct ProtocolDraftItem: Hashable {
    var slot: ProtocolSlot
    var supplementName: String
    var supplementKey: String?
    var amount: Double
    var unit: SupplementUnit

    init(slot: ProtocolSlot, supplementName: String, supplementKey: String?, amount: Double, unit: SupplementUnit) {
        self.slot = slot
        self.supplementName = supplementName
        self.supplementKey = supplementKey
        self.amount = amount
        self.unit = unit
    }

    init(item: ProtocolItem) {
        self.slot = item.slot
        self.supplementName = item.supplementName
        self.supplementKey = item.supplementKey
        self.amount = item.amount
        self.unit = item.unit
    }

    func toModel(version: ProtocolVersion) -> ProtocolItem {
        ProtocolItem(slot: slot, supplementName: supplementName, supplementKey: supplementKey, amount: amount, unit: unit, version: version)
    }
}

private struct ProtocolDraftRow: View {
    @Binding var item: ProtocolDraftItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.supplementName)
                .font(.system(.headline, design: .rounded))

            HStack {
                TextField("Amount", value: $item.amount, format: .number)
                    .keyboardType(.decimalPad)
                Picker("Unit", selection: $item.unit) {
                    ForEach(SupplementUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
            }
        }
    }
}

private struct SupplementPicker: View {
    @Environment(\.dismiss) private var dismiss

    let slot: ProtocolSlot
    let onSelect: (SupplementTemplate) -> Void

    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List(filtered) { template in
                Button {
                    onSelect(template)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                        Text(template.defaultUnit.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search supplements")
            .navigationTitle("Add \(slot.rawValue)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var filtered: [SupplementTemplate] {
        SupplementCatalog.search(searchText)
    }
}

private struct ProtocolCalendarView: View {
    let protocolID: UUID
    let logs: [ProtocolLog]

    @State private var monthOffset: Int = 0

    private var calendar: Calendar { .current }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    monthOffset -= 1
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.white)
                }

                Spacer()

                Text(monthTitle)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    monthOffset += 1
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }

                ForEach(daysInMonth, id: \.self) { day in
                    if day == 0 {
                        Color.clear.frame(height: 28)
                    } else {
                        dayCell(day)
                    }
                }
            }
        }
    }

    private var weekdaySymbols: [String] {
        calendar.shortStandaloneWeekdaySymbols
    }

    private var monthTitle: String {
        let date = calendar.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private var daysInMonth: [Int] {
        let date = calendar.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
        let range = calendar.range(of: .day, in: .month, for: date) ?? 1..<31
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        let weekday = calendar.component(.weekday, from: firstDay)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        return Array(repeating: 0, count: leading) + Array(range)
    }

    private func dayCell(_ day: Int) -> some View {
        let date = dateFor(day: day)
        let dayLogs = logs.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        let completed = dayLogs.filter { $0.status == .completed }
        let missed = dayLogs.filter { $0.status == .missed }

        return VStack(spacing: 4) {
            Text("\(day)")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 3) {
                if !completed.isEmpty {
                    Circle().fill(Color.neonCyan).frame(width: 5, height: 5)
                }
                if !missed.isEmpty {
                    Circle().fill(Color.neonAmber).frame(width: 5, height: 5)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 32)
        .padding(6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func dateFor(day: Int) -> Date {
        let base = calendar.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
        var comps = calendar.dateComponents([.year, .month], from: base)
        comps.day = day
        return calendar.date(from: comps)?.startOfDay ?? Date().startOfDay
    }
}

private enum VersionBump: String, CaseIterable, Identifiable {
    case keep
    case patch
    case major

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keep: return "Keep current version"
        case .patch: return "Increment minor (v1.1)"
        case .major: return "Increment major (v2.0)"
        }
    }
}

private extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}

#Preview {
    ProtocolsView()
}
