import SwiftUI
import SwiftData

struct ProtocolsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProtocolPlan.updatedAt, order: .reverse) private var protocols: [ProtocolPlan]
    @State private var isCreating = false
    @State private var pendingDelete: ProtocolPlan?
    @State private var editTarget: ProtocolPlan?
    @State private var openTargetID: UUID?
    @State private var selectedCategory: TemplateCategory = .all
    @State private var selectedTemplate: ProtocolTemplate?
    @State private var createdPlan: ProtocolPlan?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        protocolsOverviewCard
                        templatesSection

                        if protocols.isEmpty {
                            emptyState
                        } else {
                            if !activeProtocols.isEmpty {
                                sectionHeader("Active", systemImage: "bolt.circle.fill")
                                ForEach(activeProtocols) { plan in
                                    protocolRow(plan)
                                }
                            }

                            if !inactiveProtocols.isEmpty {
                                sectionHeader("Inactive", systemImage: "pause.circle.fill")
                                ForEach(inactiveProtocols) { plan in
                                    protocolRow(plan)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Protocols")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isCreating) {
                ProtocolEditorView(protocolPlan: nil)
            }
            .sheet(item: $editTarget) { plan in
                ProtocolEditorView(protocolPlan: plan)
            }
            .sheet(item: $selectedTemplate) { template in
                TemplatePreviewSheet(
                    template: template,
                    onCreate: {
                        createPlan(from: template)
                        selectedTemplate = nil
                    }
                )
            }
            .sheet(item: $createdPlan) { plan in
                NavigationStack {
                    ProtocolDetailView(protocolPlan: plan)
                }
            }
            .alert("Delete Protocol?", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })) {
                Button("Delete", role: .destructive) {
                    if let plan = pendingDelete {
                        modelContext.delete(plan)
                    }
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: {
                Text("This will remove the protocol and all versions.")
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isCreating = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .accessibilityLabel("Create Protocol")
                }
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
                .foregroundStyle(Color.textPrimary)

            Text("Create your first supplement protocol to track daily routines.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .glassCard()
    }

    private var activeProtocols: [ProtocolPlan] {
        protocols.filter { $0.isActive }
    }

    private var inactiveProtocols: [ProtocolPlan] {
        protocols.filter { !$0.isActive }
    }

    private var protocolsOverviewCard: some View {
        let activeCount = activeProtocols.count
        let inactiveCount = inactiveProtocols.count
        let total = protocols.count
        let activePercent = total == 0 ? 0 : Int((Double(activeCount) / Double(total)) * 100)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Protocol Suite")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Button {
                    isCreating = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("New")
                    }
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                }
                .buttonStyle(SecondaryActionButtonStyle())
            }

            HStack(spacing: 12) {
                ProtocolMetricTile(title: "Active", value: "\(activeCount)", tint: Color.neonCyan)
                ProtocolMetricTile(title: "Inactive", value: "\(inactiveCount)", tint: Color.neonAmber)
            }

            Text("\(activePercent)% active")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Color.textSecondary)
        }
        .glassCard()
    }

    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Templates", systemImage: "sparkles")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(TemplateCategory.allCases) { category in
                        CategoryChip(
                            title: category.rawValue,
                            tint: tint(for: category),
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal, 4)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(filteredTemplates) { template in
                        TemplatePreviewCard(template: template) {
                            selectedTemplate = template
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private var filteredTemplates: [ProtocolTemplate] {
        let all = ProtocolTemplateCatalog.all
        guard selectedCategory != .all else { return all }
        return all.filter { $0.category == selectedCategory }
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

    @ViewBuilder
    private func protocolRow(_ plan: ProtocolPlan) -> some View {
        ZStack {
            NavigationLink(isActive: Binding(get: { openTargetID == plan.id }, set: { if !$0 { openTargetID = nil } })) {
                ProtocolDetailView(protocolPlan: plan)
            } label: {
                EmptyView()
            }
            .opacity(0)

            NavigationLink {
                ProtocolDetailView(protocolPlan: plan)
            } label: {
                ProtocolCard(plan: plan)
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button {
                    editTarget = plan
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button {
                    plan.isActive.toggle()
                    plan.updatedAt = Date()
                } label: {
                    Label(plan.isActive ? "Deactivate" : "Activate", systemImage: plan.isActive ? "pause.circle" : "play.circle")
                }
                Button(role: .destructive) {
                    pendingDelete = plan
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private func createPlan(from template: ProtocolTemplate) {
        let plan = ProtocolPlan(name: template.name)
        let version = ProtocolVersion(major: 1, minor: 0, plan: plan)
        let items = template.items.map { item in
            ProtocolItem(
                slot: item.slot,
                supplementName: item.supplementName,
                supplementKey: item.supplementKey,
                amount: item.amount,
                unit: item.unit,
                version: version
            )
        }
        version.items = items
        plan.versions = [version]
        modelContext.insert(plan)

        for slot in ProtocolSlot.allCases {
            let hasSlot = template.items.contains { $0.slot == slot }
            guard hasSlot else { continue }
            NotificationManager.shared.setSlotEnabled(true, for: plan.id, slot: slot)
            if let override = template.reminderOverrides[slot] {
                NotificationManager.shared.setTime(override, for: plan.id, slot: slot)
            }
        }

        rescheduleAll()
        createdPlan = plan
    }

    private func rescheduleAll() {
        let planDescriptor = FetchDescriptor<ProtocolPlan>()
        let logDescriptor = FetchDescriptor<ProtocolLog>()
        let plans = (try? modelContext.fetch(planDescriptor)) ?? protocols
        let logItems = (try? modelContext.fetch(logDescriptor)) ?? []
        NotificationManager.shared.rescheduleAll(
            activeProtocols: plans.filter { $0.isActive },
            logs: logItems
        )
    }

    private func tint(for category: TemplateCategory) -> Color {
        switch category {
        case .all: return Color.textSecondary
        case .foundation: return Color.neonCyan
        case .sleep: return Color.neonAmber
        case .focus: return Color.neonPink
        case .performance: return Color.neonCyan.opacity(0.9)
        }
    }
}

private struct ProtocolCard: View {
    let plan: ProtocolPlan

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(plan.name)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Color.textPrimary)

                    StatusPill(
                        text: plan.isActive ? "Active" : "Inactive",
                        tint: plan.isActive ? Color.neonCyan : Color.neonAmber
                    )
                }

                Text("Updated \(plan.updatedAt, style: .date)")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            if let current = plan.currentVersion {
                Text(current.label)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .glassCard()
    }
}

private struct ProtocolMetricTile: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(tint)
                    .frame(width: 6, height: 6)
                Text(title)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(BevelInsetSurface(cornerRadius: 16))
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

private struct TemplatePreviewCard: View {
    let template: ProtocolTemplate
    let onPreview: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(template.name)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                    Text(template.summary)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                TemplateCategoryPill(text: template.category.rawValue, tint: tint(for: template.category))
            }

            Text("Includes: \(template.highlights)")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Color.textTertiary)
                .lineLimit(2)

            HStack(spacing: 8) {
                ForEach(template.slotCounts) { item in
                    TemplateSlotPill(slot: item.slot, count: item.count)
                }
                Spacer()
            }

            Button(action: onPreview) {
                HStack {
                    Text("Preview")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
            }
            .buttonStyle(SecondaryActionButtonStyle())
        }
        .frame(width: 280)
        .glassCard()
    }

    private func tint(for category: TemplateCategory) -> Color {
        switch category {
        case .all: return Color.textSecondary
        case .foundation: return Color.neonCyan
        case .sleep: return Color.neonAmber
        case .focus: return Color.neonPink
        case .performance: return Color.neonCyan.opacity(0.9)
        }
    }
}

private struct TemplatePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let template: ProtocolTemplate
    let onCreate: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(template.name)
                                .font(.system(.title2, design: .rounded).weight(.semibold))
                                .foregroundStyle(Color.textPrimary)
                            Text(template.summary)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(Color.textSecondary)
                        }
                        .glassCard()

                        ForEach(ProtocolSlot.allCases) { slot in
                            let items = template.items.filter { $0.slot == slot }
                            if !items.isEmpty {
                                TemplateSlotSection(slot: slot, items: items)
                            }
                        }

                        Button(action: {
                            onCreate()
                            dismiss()
                        }) {
                            HStack {
                                Text("Add Protocol")
                                    .font(.system(.headline, design: .rounded))
                                Spacer()
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                        }
                        .buttonStyle(PrimaryActionButtonStyle(tint: Color.neonCyan))
                        .padding(.bottom, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Template Preview")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

private struct TemplateSlotSection: View {
    let slot: ProtocolSlot
    let items: [ProtocolTemplateItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(Color.neonCyan)
                Text(slot.rawValue)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("\(items.count)")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(BevelInsetSurface(cornerRadius: 10))
            }

            ForEach(items) { item in
                TemplateItemRow(item: item)
            }
        }
        .glassCard()
    }

    private var icon: String {
        switch slot {
        case .morning: return "sun.max.fill"
        case .daytime: return "sun.haze.fill"
        case .night: return "moon.stars.fill"
        }
    }
}

private struct TemplateItemRow: View {
    let item: ProtocolTemplateItem

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.neonCyan.opacity(0.35))
                .frame(width: 6, height: 6)

            Text(item.supplementName)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Text("\(item.amount.formatted(.number.precision(.fractionLength(0...2)))) \(item.unit.rawValue)")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(BevelInsetSurface(cornerRadius: 10))
        }
        .padding(.vertical, 2)
    }
}

private struct TemplateSlotPill: View {
    let slot: ProtocolSlot
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.neonCyan)
            Text("\(count)")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(BevelInsetSurface(cornerRadius: 12))
    }

    private var icon: String {
        switch slot {
        case .morning: return "sun.max.fill"
        case .daytime: return "sun.haze.fill"
        case .night: return "moon.stars.fill"
        }
    }
}

private struct TemplateCategoryPill: View {
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

private struct CategoryChip: View {
    let title: String
    let tint: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(isSelected ? Color.textPrimary : tint)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    ZStack {
                        BevelInsetSurface(cornerRadius: 14)
                        if isSelected {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(tint.opacity(0.18))
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProtocolsView()
}
