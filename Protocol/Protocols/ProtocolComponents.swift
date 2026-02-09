import SwiftUI

struct ProtocolDraftItem: Hashable {
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

enum VersionBump {
    case keep
    case patch
    case major
}

struct SupplementPicker: View {
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

extension ProtocolPlan {
    var currentVersion: ProtocolVersion? {
        versions?.sorted(by: { $0.createdAt > $1.createdAt }).first
    }

    var sortedVersions: [ProtocolVersion] {
        versions?.sorted(by: { $0.createdAt > $1.createdAt }) ?? []
    }
}
