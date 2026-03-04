import Foundation

struct ProtocolTemplate: Identifiable {
    let id: String
    let name: String
    let summary: String
    let category: TemplateCategory
    let items: [ProtocolTemplateItem]
    let reminderOverrides: [ProtocolSlot: DateComponents]

    var highlights: String {
        var seen: Set<String> = []
        var names: [String] = []
        for item in items {
            if !seen.contains(item.supplementName) {
                names.append(item.supplementName)
                seen.insert(item.supplementName)
            }
        }

        if names.count <= 3 {
            return names.joined(separator: ", ")
        }
        let prefix = names.prefix(3).joined(separator: ", ")
        return "\(prefix) + \(names.count - 3) more"
    }

    var slotCounts: [TemplateSlotCount] {
        ProtocolSlot.allCases.compactMap { slot in
            let count = items.filter { $0.slot == slot }.count
            guard count > 0 else { return nil }
            return TemplateSlotCount(slot: slot, count: count)
        }
    }
}

struct ProtocolTemplateItem: Identifiable {
    let id = UUID()
    let slot: ProtocolSlot
    let supplementName: String
    let supplementKey: String?
    let amount: Double
    let unit: SupplementUnit
}

struct TemplateSlotCount: Identifiable {
    let id = UUID()
    let slot: ProtocolSlot
    let count: Int
}

enum TemplateCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case foundation = "Foundation"
    case sleep = "Sleep"
    case focus = "Focus"
    case performance = "Performance"

    var id: String { rawValue }
}

enum ProtocolTemplateCatalog {
    static let all: [ProtocolTemplate] = [
        ProtocolTemplate(
            id: "foundation_core",
            name: "Foundation Core",
            summary: "Essential daily micronutrients plus omega-3 with nighttime magnesium.",
            category: .foundation,
            items: [
                ProtocolTemplateItem(slot: .morning, supplementName: "Vitamin D3", supplementKey: "vitamin_d3", amount: 2000, unit: .iu),
                ProtocolTemplateItem(slot: .morning, supplementName: "Vitamin K2", supplementKey: "vitamin_k2", amount: 100, unit: .mcg),
                ProtocolTemplateItem(slot: .morning, supplementName: "Omega-3 (EPA/DHA)", supplementKey: "omega3", amount: 1, unit: .g),
                ProtocolTemplateItem(slot: .daytime, supplementName: "Vitamin C", supplementKey: "vitamin_c", amount: 500, unit: .mg),
                ProtocolTemplateItem(slot: .daytime, supplementName: "Probiotics", supplementKey: "probiotics", amount: 1, unit: .pills),
                ProtocolTemplateItem(slot: .night, supplementName: "Magnesium Glycinate", supplementKey: "magnesium_glycinate", amount: 300, unit: .mg)
            ],
            reminderOverrides: [:]
        ),
        ProtocolTemplate(
            id: "sleep_recovery",
            name: "Sleep Recovery",
            summary: "Night stack to support relaxation and sleep quality.",
            category: .sleep,
            items: [
                ProtocolTemplateItem(slot: .night, supplementName: "Magnesium Glycinate", supplementKey: "magnesium_glycinate", amount: 300, unit: .mg),
                ProtocolTemplateItem(slot: .night, supplementName: "Glycine", supplementKey: "glycine", amount: 3, unit: .g),
                ProtocolTemplateItem(slot: .night, supplementName: "L-Theanine", supplementKey: "l_theanine", amount: 200, unit: .mg),
                ProtocolTemplateItem(slot: .night, supplementName: "Melatonin", supplementKey: "melatonin", amount: 0.3, unit: .mg)
            ],
            reminderOverrides: [.night: DateComponents(hour: 21, minute: 30)]
        ),
        ProtocolTemplate(
            id: "cognitive_focus",
            name: "Cognitive Focus",
            summary: "Morning adaptogens and daytime clarity support.",
            category: .focus,
            items: [
                ProtocolTemplateItem(slot: .morning, supplementName: "Rhodiola", supplementKey: "rhodiola", amount: 200, unit: .mg),
                ProtocolTemplateItem(slot: .morning, supplementName: "L-Theanine", supplementKey: "l_theanine", amount: 200, unit: .mg),
                ProtocolTemplateItem(slot: .morning, supplementName: "Vitamin B12", supplementKey: "vitamin_b12", amount: 500, unit: .mcg),
                ProtocolTemplateItem(slot: .daytime, supplementName: "CoQ10", supplementKey: "coq10", amount: 100, unit: .mg),
                ProtocolTemplateItem(slot: .daytime, supplementName: "Omega-3 (EPA/DHA)", supplementKey: "omega3", amount: 1, unit: .g)
            ],
            reminderOverrides: [:]
        ),
        ProtocolTemplate(
            id: "training_performance",
            name: "Training Performance",
            summary: "Performance and recovery stack around training days.",
            category: .performance,
            items: [
                ProtocolTemplateItem(slot: .morning, supplementName: "Creatine", supplementKey: "creatine", amount: 5, unit: .g),
                ProtocolTemplateItem(slot: .morning, supplementName: "NAD+ Precursor", supplementKey: "nad_precursor", amount: 250, unit: .mg),
                ProtocolTemplateItem(slot: .daytime, supplementName: "Collagen", supplementKey: "collagen", amount: 10, unit: .g),
                ProtocolTemplateItem(slot: .night, supplementName: "Magnesium Glycinate", supplementKey: "magnesium_glycinate", amount: 300, unit: .mg),
                ProtocolTemplateItem(slot: .night, supplementName: "Vitamin C", supplementKey: "vitamin_c", amount: 500, unit: .mg)
            ],
            reminderOverrides: [:]
        )
    ]
}
