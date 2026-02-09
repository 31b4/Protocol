import Foundation

struct SupplementTemplate: Identifiable, Hashable {
    let id: String
    let name: String
    let defaultUnit: SupplementUnit
    let aliases: [String]

    init(id: String, name: String, defaultUnit: SupplementUnit, aliases: [String] = []) {
        self.id = id
        self.name = name
        self.defaultUnit = defaultUnit
        self.aliases = aliases
    }
}

enum SupplementCatalog {
    static let all: [SupplementTemplate] = [
        SupplementTemplate(id: "vitamin_d3", name: "Vitamin D3", defaultUnit: .iu, aliases: ["D3", "Cholecalciferol"]),
        SupplementTemplate(id: "vitamin_k2", name: "Vitamin K2", defaultUnit: .mcg, aliases: ["MK-7", "K2"]),
        SupplementTemplate(id: "vitamin_c", name: "Vitamin C", defaultUnit: .mg, aliases: ["Ascorbic Acid"]),
        SupplementTemplate(id: "vitamin_b12", name: "Vitamin B12", defaultUnit: .mcg, aliases: ["Cobalamin"]),
        SupplementTemplate(id: "folate", name: "Folate", defaultUnit: .mcg, aliases: ["Folic Acid"]),
        SupplementTemplate(id: "vitamin_a", name: "Vitamin A", defaultUnit: .iu, aliases: ["Retinol"]),
        SupplementTemplate(id: "vitamin_e", name: "Vitamin E", defaultUnit: .iu, aliases: ["Tocopherol"]),
        SupplementTemplate(id: "vitamin_b6", name: "Vitamin B6", defaultUnit: .mg, aliases: ["Pyridoxine"]),
        SupplementTemplate(id: "biotin", name: "Biotin", defaultUnit: .mcg),
        SupplementTemplate(id: "thiamine", name: "Thiamine (B1)", defaultUnit: .mg),
        SupplementTemplate(id: "riboflavin", name: "Riboflavin (B2)", defaultUnit: .mg),
        SupplementTemplate(id: "niacin", name: "Niacin (B3)", defaultUnit: .mg),
        SupplementTemplate(id: "pantothenic", name: "Pantothenic Acid (B5)", defaultUnit: .mg),

        SupplementTemplate(id: "omega3", name: "Omega-3 (EPA/DHA)", defaultUnit: .g, aliases: ["Fish Oil"]),
        SupplementTemplate(id: "magnesium_glycinate", name: "Magnesium Glycinate", defaultUnit: .mg, aliases: ["Magnesium"]),
        SupplementTemplate(id: "zinc", name: "Zinc", defaultUnit: .mg),
        SupplementTemplate(id: "selenium", name: "Selenium", defaultUnit: .mcg),
        SupplementTemplate(id: "iodine", name: "Iodine", defaultUnit: .mcg),
        SupplementTemplate(id: "calcium", name: "Calcium", defaultUnit: .mg),
        SupplementTemplate(id: "potassium", name: "Potassium", defaultUnit: .mg),
        SupplementTemplate(id: "iron", name: "Iron", defaultUnit: .mg),
        SupplementTemplate(id: "copper", name: "Copper", defaultUnit: .mg),
        SupplementTemplate(id: "chromium", name: "Chromium", defaultUnit: .mcg),
        SupplementTemplate(id: "manganese", name: "Manganese", defaultUnit: .mg),
        SupplementTemplate(id: "boron", name: "Boron", defaultUnit: .mg),

        SupplementTemplate(id: "coq10", name: "CoQ10", defaultUnit: .mg, aliases: ["Ubiquinone", "Ubiquinol"]),
        SupplementTemplate(id: "creatine", name: "Creatine", defaultUnit: .g),
        SupplementTemplate(id: "collagen", name: "Collagen", defaultUnit: .g),
        SupplementTemplate(id: "ashwagandha", name: "Ashwagandha", defaultUnit: .mg),
        SupplementTemplate(id: "rhodiola", name: "Rhodiola", defaultUnit: .mg),
        SupplementTemplate(id: "l_theanine", name: "L-Theanine", defaultUnit: .mg),
        SupplementTemplate(id: "glycine", name: "Glycine", defaultUnit: .g),
        SupplementTemplate(id: "probiotics", name: "Probiotics", defaultUnit: .pills),
        SupplementTemplate(id: "melatonin", name: "Melatonin", defaultUnit: .mg),
        SupplementTemplate(id: "nad_precursor", name: "NAD+ Precursor", defaultUnit: .mg, aliases: ["NR", "NMN"])
    ]

    static func search(_ query: String) -> [SupplementTemplate] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return all }
        return all.filter { template in
            if template.name.localizedCaseInsensitiveContains(trimmed) { return true }
            return template.aliases.contains { $0.localizedCaseInsensitiveContains(trimmed) }
        }
    }
}
