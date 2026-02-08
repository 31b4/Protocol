import Foundation

struct BiomarkerTemplate: Identifiable, Hashable {
    let id: String
    let name: String
    let category: BiomarkerCategory
    let defaultUnit: BiomarkerUnit
    let aliases: [String]
    let minReference: Double?
    let maxReference: Double?

    init(
        id: String,
        name: String,
        category: BiomarkerCategory,
        defaultUnit: BiomarkerUnit,
        aliases: [String] = [],
        minReference: Double? = nil,
        maxReference: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.defaultUnit = defaultUnit
        self.aliases = aliases
        self.minReference = minReference
        self.maxReference = maxReference
    }
}

enum BiomarkerCatalog {
    static let all: [BiomarkerTemplate] = [
        BiomarkerTemplate(id: "ldl", name: "LDL Cholesterol", category: .lipids, defaultUnit: .mgdL, aliases: ["LDL-koleszterin", "LDL", "Low Density Lipoprotein"], minReference: 0, maxReference: 100),
        BiomarkerTemplate(id: "hdl", name: "HDL Cholesterol", category: .lipids, defaultUnit: .mgdL, aliases: ["HDL-koleszterin", "HDL", "High Density Lipoprotein"], minReference: 40, maxReference: 100),
        BiomarkerTemplate(id: "triglycerides", name: "Triglycerides", category: .lipids, defaultUnit: .mgdL, aliases: ["Triglicerid", "Triglycerid"], minReference: 0, maxReference: 150),
        BiomarkerTemplate(id: "total_chol", name: "Total Cholesterol", category: .lipids, defaultUnit: .mgdL, aliases: ["Összkoleszterin", "Total chol."], minReference: 0, maxReference: 200),

        BiomarkerTemplate(id: "hba1c", name: "HbA1c", category: .metabolic, defaultUnit: .percent, aliases: ["HbA1c", "HBA1C"], minReference: 4.0, maxReference: 5.6),
        BiomarkerTemplate(id: "fasting_glucose", name: "Fasting Glucose", category: .metabolic, defaultUnit: .mgdL, aliases: ["Glükóz", "Glukoz", "Vércukor", "Blood Glucose", "Glucose"], minReference: 70, maxReference: 99),
        BiomarkerTemplate(id: "insulin", name: "Fasting Insulin", category: .metabolic, defaultUnit: .uiuML, aliases: ["Inzulin", "Insulin"], minReference: 2, maxReference: 25),

        BiomarkerTemplate(id: "vitd", name: "Vitamin D (25-OH)", category: .vitamins, defaultUnit: .ngmL, aliases: ["D-vitamin", "25-OH Vitamin D", "25(OH)D"], minReference: 30, maxReference: 100),
        BiomarkerTemplate(id: "b12", name: "Vitamin B12", category: .vitamins, defaultUnit: .pgmL, aliases: ["B12-vitamin", "Cobalamin"], minReference: 200, maxReference: 900),
        BiomarkerTemplate(id: "folate", name: "Folate", category: .vitamins, defaultUnit: .ngmL, aliases: ["Folsav", "Folate"], minReference: 3, maxReference: 20),

        BiomarkerTemplate(id: "hscrp", name: "High-Sensitivity C-Reactive Protein", category: .inflammation, defaultUnit: .mgL, aliases: ["hs-CRP", "CRP", "C-reaktív protein"], minReference: 0, maxReference: 3.0),
        BiomarkerTemplate(id: "il6", name: "Interleukin-6", category: .inflammation, defaultUnit: .pgmL, aliases: ["IL-6"]),

        BiomarkerTemplate(id: "testosterone_total", name: "Testosterone (Total)", category: .hormones, defaultUnit: .ngmL, aliases: ["Tesztoszteron", "Testosterone Total"], minReference: 2.5, maxReference: 9.5),
        BiomarkerTemplate(id: "testosterone_free", name: "Testosterone (Free)", category: .hormones, defaultUnit: .pgmL, aliases: ["Szabad tesztoszteron", "Free Testosterone"]),
        BiomarkerTemplate(id: "estradiol", name: "Estradiol (E2)", category: .hormones, defaultUnit: .pgmL, aliases: ["Ösztradiol", "Estradiol"]),
        BiomarkerTemplate(id: "dhea_s", name: "DHEA-S", category: .hormones, defaultUnit: .umolL, aliases: ["DHEA-S"]),

        BiomarkerTemplate(id: "tsh", name: "TSH", category: .thyroid, defaultUnit: .uiuML, aliases: ["TSH", "Tireotrop hormon"], minReference: 0.4, maxReference: 4.0),
        BiomarkerTemplate(id: "ft3", name: "Free T3", category: .thyroid, defaultUnit: .pgmL, aliases: ["Szabad T3", "fT3"]),
        BiomarkerTemplate(id: "ft4", name: "Free T4", category: .thyroid, defaultUnit: .ngmL, aliases: ["Szabad T4", "fT4"]),

        BiomarkerTemplate(id: "hemoglobin", name: "Hemoglobin", category: .hematology, defaultUnit: .mgdL, aliases: ["Hemoglobin", "Hgb", "Hb"]),
        BiomarkerTemplate(id: "hematocrit", name: "Hematocrit", category: .hematology, defaultUnit: .percent, aliases: ["Hematokrit", "HCT"]),
        BiomarkerTemplate(id: "ferritin", name: "Ferritin", category: .hematology, defaultUnit: .ngmL, aliases: ["Ferritin"], minReference: 30, maxReference: 400),

        BiomarkerTemplate(id: "creatinine", name: "Creatinine", category: .kidney, defaultUnit: .mgdL, aliases: ["Kreatinin", "Creatinine"], minReference: 0.6, maxReference: 1.3),
        BiomarkerTemplate(id: "bun", name: "BUN", category: .kidney, defaultUnit: .mgdL, aliases: ["Karbamid", "Urea", "BUN"], minReference: 7, maxReference: 20),

        BiomarkerTemplate(id: "alt", name: "ALT", category: .liver, defaultUnit: .iul, aliases: ["ALT", "GPT", "ALAT"], minReference: 7, maxReference: 56),
        BiomarkerTemplate(id: "ast", name: "AST", category: .liver, defaultUnit: .iul, aliases: ["AST", "GOT", "ASAT"], minReference: 10, maxReference: 40),
        BiomarkerTemplate(id: "albumin", name: "Albumin", category: .liver, defaultUnit: .mgdL, aliases: ["Albumin"], minReference: 3.5, maxReference: 5.0),

        BiomarkerTemplate(id: "sodium", name: "Sodium", category: .electrolytes, defaultUnit: .mmoll, aliases: ["Nátrium", "Sodium"], minReference: 135, maxReference: 145),
        BiomarkerTemplate(id: "potassium", name: "Potassium", category: .electrolytes, defaultUnit: .mmoll, aliases: ["Kálium", "Potassium"], minReference: 3.5, maxReference: 5.1)
    ]

    static func search(_ query: String) -> [BiomarkerTemplate] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return all }
        return all.filter { template in
            if template.name.localizedCaseInsensitiveContains(trimmed) { return true }
            return template.aliases.contains { $0.localizedCaseInsensitiveContains(trimmed) }
        }
    }

    static func matchTemplate(in line: String) -> BiomarkerTemplate? {
        let normalizedLine = normalize(line)
        return all.first { template in
            let nameMatch = normalize(template.name)
            if normalizedLine.contains(nameMatch) { return true }
            return template.aliases.contains { alias in
                normalizedLine.contains(normalize(alias))
            }
        }
    }

    private static func normalize(_ text: String) -> String {
        let folded = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let allowed = folded.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) || $0 == " " }
        return String(String.UnicodeScalarView(allowed)).replacingOccurrences(of: " ", with: "")
    }
}
