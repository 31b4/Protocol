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

        BiomarkerTemplate(id: "testosterone_total", name: "Testosterone (Total)", category: .hormones, defaultUnit: .nmoll, aliases: ["Tesztoszteron", "Testosterone Total"], minReference: 2.5, maxReference: 27.35),
        BiomarkerTemplate(id: "testosterone_free", name: "Testosterone (Free)", category: .hormones, defaultUnit: .pgmL, aliases: ["Szabad tesztoszteron", "Free Testosterone"]),
        BiomarkerTemplate(id: "estradiol", name: "Estradiol (E2)", category: .hormones, defaultUnit: .pgmL, aliases: ["Ösztradiol", "Estradiol"]),
        BiomarkerTemplate(id: "dhea_s", name: "DHEA-S", category: .hormones, defaultUnit: .umolL, aliases: ["DHEA-S"]),

        BiomarkerTemplate(id: "tsh", name: "TSH", category: .thyroid, defaultUnit: .uiuML, aliases: ["TSH", "Tireotrop hormon"], minReference: 0.4, maxReference: 4.0),
        BiomarkerTemplate(id: "ft3", name: "Free T3", category: .thyroid, defaultUnit: .pgmL, aliases: ["Szabad T3", "fT3"]),
        BiomarkerTemplate(id: "ft4", name: "Free T4", category: .thyroid, defaultUnit: .ngmL, aliases: ["Szabad T4", "fT4"]),

        BiomarkerTemplate(id: "esr", name: "Erythrocyte Sedimentation Rate", category: .inflammation, defaultUnit: .mmHour, aliases: ["Vörösvérsejt süllyedés", "Süllyedés", "ESR"], minReference: 2, maxReference: 15),
        BiomarkerTemplate(id: "wbc", name: "White Blood Cell Count", category: .hematology, defaultUnit: .gigaL, aliases: ["Fehérvérsejtszám", "WBC", "Fehérvérsejt"], minReference: 4.0, maxReference: 10.0),
        BiomarkerTemplate(id: "rbc", name: "Red Blood Cell Count", category: .hematology, defaultUnit: .teraL, aliases: ["Vörösvérsejtszám", "RBC"], minReference: 4.5, maxReference: 6.0),
        BiomarkerTemplate(id: "hemoglobin", name: "Hemoglobin", category: .hematology, defaultUnit: .gL, aliases: ["Hemoglobin", "Hgb", "Hb"], minReference: 140, maxReference: 180),
        BiomarkerTemplate(id: "hematocrit", name: "Hematocrit", category: .hematology, defaultUnit: .lL, aliases: ["Hematokrit", "HCT"], minReference: 0.36, maxReference: 0.54),
        BiomarkerTemplate(id: "mcv", name: "MCV", category: .hematology, defaultUnit: .fL, aliases: ["MCV", "Mean Corpuscular Volume"], minReference: 80.0, maxReference: 95.0),
        BiomarkerTemplate(id: "mch", name: "MCH", category: .hematology, defaultUnit: .pg, aliases: ["MCH", "Mean Corpuscular Hemoglobin"], minReference: 24.0, maxReference: 34.0),
        BiomarkerTemplate(id: "mchc", name: "MCHC", category: .hematology, defaultUnit: .gL, aliases: ["MCHC", "Mean Corpuscular Hemoglobin Concentration"], minReference: 305, maxReference: 355),
        BiomarkerTemplate(id: "rdw", name: "RDW-CV", category: .hematology, defaultUnit: .percent, aliases: ["RDW-CV", "RDW"], minReference: 11.6, maxReference: 13.7),
        BiomarkerTemplate(id: "platelets", name: "Platelet Count", category: .hematology, defaultUnit: .gigaL, aliases: ["Trombocitaszám", "Platelets", "PLT"], minReference: 150, maxReference: 400),
        BiomarkerTemplate(id: "mpv", name: "MPV", category: .hematology, defaultUnit: .fL, aliases: ["MPV", "Mean Platelet Volume"], minReference: 7.8, maxReference: 11.0),
        BiomarkerTemplate(id: "ferritin", name: "Ferritin", category: .hematology, defaultUnit: .ngmL, aliases: ["Ferritin"], minReference: 30, maxReference: 400),

        BiomarkerTemplate(id: "creatinine", name: "Creatinine", category: .kidney, defaultUnit: .umolL, aliases: ["Kreatinin", "Creatinine"], minReference: 74, maxReference: 120),
        BiomarkerTemplate(id: "urea", name: "Urea", category: .kidney, defaultUnit: .mmoll, aliases: ["Karbamid", "Urea"], minReference: 2.5, maxReference: 7.5),
        BiomarkerTemplate(id: "bun", name: "BUN", category: .kidney, defaultUnit: .mgdL, aliases: ["BUN"], minReference: 7, maxReference: 20),
        BiomarkerTemplate(id: "egfr", name: "eGFR (EPI)", category: .kidney, defaultUnit: .mlMin173, aliases: ["EGFR", "EGFR-EPI"], minReference: 90, maxReference: 200),
        BiomarkerTemplate(id: "uric_acid", name: "Uric Acid", category: .kidney, defaultUnit: .umolL, aliases: ["Húgysav", "Uric acid"], minReference: 200, maxReference: 416),

        BiomarkerTemplate(id: "alt", name: "ALT", category: .liver, defaultUnit: .iul, aliases: ["ALT", "GPT", "ALAT"], minReference: 7, maxReference: 56),
        BiomarkerTemplate(id: "ast", name: "AST", category: .liver, defaultUnit: .iul, aliases: ["AST", "GOT", "ASAT"], minReference: 10, maxReference: 40),
        BiomarkerTemplate(id: "bilirubin_total", name: "Total Bilirubin", category: .liver, defaultUnit: .umolL, aliases: ["Összbilirubin", "Total bilirubin"], minReference: 5.1, maxReference: 17.1),
        BiomarkerTemplate(id: "ggt", name: "Gamma-GT", category: .liver, defaultUnit: .iul, aliases: ["Gamma-GT", "GGT"], minReference: 11, maxReference: 61),
        BiomarkerTemplate(id: "alp", name: "Alkaline Phosphatase", category: .liver, defaultUnit: .iul, aliases: ["Alkalikus foszfatáz", "ALP"], minReference: 44, maxReference: 147),
        BiomarkerTemplate(id: "albumin", name: "Albumin", category: .liver, defaultUnit: .mgdL, aliases: ["Albumin"], minReference: 3.5, maxReference: 5.0),

        BiomarkerTemplate(id: "sodium", name: "Sodium", category: .electrolytes, defaultUnit: .mmoll, aliases: ["Nátrium", "Sodium"], minReference: 135, maxReference: 145),
        BiomarkerTemplate(id: "potassium", name: "Potassium", category: .electrolytes, defaultUnit: .mmoll, aliases: ["Kálium", "Potassium"], minReference: 3.5, maxReference: 5.1),
        BiomarkerTemplate(id: "magnesium", name: "Magnesium", category: .electrolytes, defaultUnit: .mmoll, aliases: ["Magnézium", "Magnesium"], minReference: 0.7, maxReference: 1.05),
        BiomarkerTemplate(id: "non_hdl", name: "Non-HDL Cholesterol", category: .lipids, defaultUnit: .mmoll, aliases: ["non-HDL", "Non-HDL"], minReference: 0.92, maxReference: 2.50)
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
