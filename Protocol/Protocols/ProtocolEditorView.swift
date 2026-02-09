import SwiftUI
import SwiftData

struct ProtocolEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let protocolPlan: ProtocolPlan?

    @State private var name: String = ""
    @State private var morningItems: [ProtocolDraftItem] = []
    @State private var dayItems: [ProtocolDraftItem] = []
    @State private var nightItems: [ProtocolDraftItem] = []

    @State private var showCatalogSlot: ProtocolSlot?
    @State private var showVersionDialog = false
    @State private var initialName: String = ""
    @State private var initialMorning: [ProtocolDraftItem] = []
    @State private var initialDay: [ProtocolDraftItem] = []
    @State private var initialNight: [ProtocolDraftItem] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Protocol") {
                    TextField("Name", text: $name)
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
                    Button("Save") { handleSaveTapped() }
                        .disabled(!canSave)
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
                    if let current = protocolPlan.currentVersion {
                        let grouped = Dictionary(grouping: current.items ?? [], by: { $0.slot })
                        morningItems = (grouped[.morning] ?? []).map(ProtocolDraftItem.init)
                        dayItems = (grouped[.daytime] ?? []).map(ProtocolDraftItem.init)
                        nightItems = (grouped[.night] ?? []).map(ProtocolDraftItem.init)
                    }
                }
                initialName = name
                initialMorning = morningItems
                initialDay = dayItems
                initialNight = nightItems
            }
            .alert("Save Version", isPresented: $showVersionDialog) {
                if let current = protocolPlan?.currentVersion {
                    Button("Keep \(current.label)") { save(bump: .keep) }
                    Button("Save as v\(current.major).\(current.minor + 1)") { save(bump: .patch) }
                    Button("Save as v\(current.major + 1).0") { save(bump: .major) }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Choose how to version this update.")
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

    private func handleSaveTapped() {
        let allItems = morningItems + dayItems + nightItems
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !allItems.isEmpty else { return }

        if protocolPlan == nil {
            save(bump: .keep)
        } else {
            showVersionDialog = true
        }
    }

    private func save(bump: VersionBump) {
        let allItems = morningItems + dayItems + nightItems

        if let protocolPlan {
            protocolPlan.name = name
            protocolPlan.updatedAt = Date()

            guard let current = protocolPlan.currentVersion else {
                let newVersion = ProtocolVersion(major: 1, minor: 0, plan: protocolPlan)
                let items = allItems.map { $0.toModel(version: newVersion) }
                newVersion.items = items
                protocolPlan.versions = [newVersion]
                dismiss()
                return
            }

            switch bump {
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

    private var canSave: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasItems = !(morningItems + dayItems + nightItems).isEmpty
        if protocolPlan == nil {
            return !trimmedName.isEmpty && hasItems
        }
        return hasItems && !trimmedName.isEmpty && isDirty
    }

    private var isDirty: Bool {
        guard name == initialName else { return true }
        return morningItems != initialMorning || dayItems != initialDay || nightItems != initialNight
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
