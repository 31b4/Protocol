import Foundation

struct BiomarkerTemplate: Identifiable, Hashable {
    let id: String
    let name: String
    let category: BiomarkerCategory
    let defaultUnit: BiomarkerUnit
    let minReference: Double?
    let maxReference: Double?

    init(
        id: String,
        name: String,
        category: BiomarkerCategory,
        defaultUnit: BiomarkerUnit,
        minReference: Double? = nil,
        maxReference: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.defaultUnit = defaultUnit
        self.minReference = minReference
        self.maxReference = maxReference
    }
}

enum BiomarkerCatalog {
    static let all: [BiomarkerTemplate] = [
        BiomarkerTemplate(id: "ldl", name: "LDL Cholesterol", category: .lipids, defaultUnit: .mgdL, minReference: 0, maxReference: 100),
        BiomarkerTemplate(id: "hdl", name: "HDL Cholesterol", category: .lipids, defaultUnit: .mgdL, minReference: 40, maxReference: 100),
        BiomarkerTemplate(id: "triglycerides", name: "Triglycerides", category: .lipids, defaultUnit: .mgdL, minReference: 0, maxReference: 150),
        BiomarkerTemplate(id: "total_chol", name: "Total Cholesterol", category: .lipids, defaultUnit: .mgdL, minReference: 0, maxReference: 200),

        BiomarkerTemplate(id: "hba1c", name: "HbA1c", category: .metabolic, defaultUnit: .percent, minReference: 4.0, maxReference: 5.6),
        BiomarkerTemplate(id: "fasting_glucose", name: "Fasting Glucose", category: .metabolic, defaultUnit: .mgdL, minReference: 70, maxReference: 99),
        BiomarkerTemplate(id: "insulin", name: "Fasting Insulin", category: .metabolic, defaultUnit: .uiuML, minReference: 2, maxReference: 25),

        BiomarkerTemplate(id: "vitd", name: "Vitamin D (25-OH)", category: .vitamins, defaultUnit: .ngmL, minReference: 30, maxReference: 100),
        BiomarkerTemplate(id: "b12", name: "Vitamin B12", category: .vitamins, defaultUnit: .pgmL, minReference: 200, maxReference: 900),
        BiomarkerTemplate(id: "folate", name: "Folate", category: .vitamins, defaultUnit: .ngmL, minReference: 3, maxReference: 20),

        BiomarkerTemplate(id: "hscrp", name: "High-Sensitivity C-Reactive Protein", category: .inflammation, defaultUnit: .mgdL, minReference: 0, maxReference: 0.3),
        BiomarkerTemplate(id: "il6", name: "Interleukin-6", category: .inflammation, defaultUnit: .pgmL),

        BiomarkerTemplate(id: "testosterone_total", name: "Testosterone (Total)", category: .hormones, defaultUnit: .ngmL, minReference: 2.5, maxReference: 9.5),
        BiomarkerTemplate(id: "testosterone_free", name: "Testosterone (Free)", category: .hormones, defaultUnit: .pgmL),
        BiomarkerTemplate(id: "estradiol", name: "Estradiol (E2)", category: .hormones, defaultUnit: .pgmL),
        BiomarkerTemplate(id: "dhea_s", name: "DHEA-S", category: .hormones, defaultUnit: .umolL),

        BiomarkerTemplate(id: "tsh", name: "TSH", category: .thyroid, defaultUnit: .uiuML, minReference: 0.4, maxReference: 4.0),
        BiomarkerTemplate(id: "ft3", name: "Free T3", category: .thyroid, defaultUnit: .pgmL),
        BiomarkerTemplate(id: "ft4", name: "Free T4", category: .thyroid, defaultUnit: .ngmL),

        BiomarkerTemplate(id: "hemoglobin", name: "Hemoglobin", category: .hematology, defaultUnit: .mgdL),
        BiomarkerTemplate(id: "hematocrit", name: "Hematocrit", category: .hematology, defaultUnit: .percent),
        BiomarkerTemplate(id: "ferritin", name: "Ferritin", category: .hematology, defaultUnit: .ngmL, minReference: 30, maxReference: 400),

        BiomarkerTemplate(id: "creatinine", name: "Creatinine", category: .kidney, defaultUnit: .mgdL, minReference: 0.6, maxReference: 1.3),
        BiomarkerTemplate(id: "bun", name: "BUN", category: .kidney, defaultUnit: .mgdL, minReference: 7, maxReference: 20),

        BiomarkerTemplate(id: "alt", name: "ALT", category: .liver, defaultUnit: .iul, minReference: 7, maxReference: 56),
        BiomarkerTemplate(id: "ast", name: "AST", category: .liver, defaultUnit: .iul, minReference: 10, maxReference: 40),
        BiomarkerTemplate(id: "albumin", name: "Albumin", category: .liver, defaultUnit: .mgdL, minReference: 3.5, maxReference: 5.0),

        BiomarkerTemplate(id: "sodium", name: "Sodium", category: .electrolytes, defaultUnit: .mmoll, minReference: 135, maxReference: 145),
        BiomarkerTemplate(id: "potassium", name: "Potassium", category: .electrolytes, defaultUnit: .mmoll, minReference: 3.5, maxReference: 5.1)
    ]

    static func search(_ query: String) -> [BiomarkerTemplate] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return all }
        return all.filter { template in
            template.name.localizedCaseInsensitiveContains(trimmed)
        }
    }
}
