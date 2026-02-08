import Foundation
import SwiftData

enum BiomarkerUnit: String, Codable, CaseIterable, Identifiable {
    case mgdL = "mg/dL"
    case mmoll = "mmol/L"
    case ngmL = "ng/mL"
    case iul = "IU/L"
    case pgmL = "pg/mL"
    case miuL = "mIU/L"
    case uiuML = "uIU/mL"
    case umolL = "umol/L"
    case percent = "%"

    var id: String { rawValue }
}

enum BiomarkerCategory: String, Codable, CaseIterable, Identifiable {
    case lipids = "Lipids"
    case hormones = "Hormones"
    case vitamins = "Vitamins"
    case inflammation = "Inflammation"
    case metabolic = "Metabolic"
    case thyroid = "Thyroid"
    case hematology = "Hematology"
    case kidney = "Kidney"
    case liver = "Liver"
    case electrolytes = "Electrolytes"

    var id: String { rawValue }
}

@Model
final class Biomarker {
    var id: UUID = UUID()
    var name: String = ""
    var value: Double = 0
    var unit: BiomarkerUnit = BiomarkerUnit.mgdL
    var date: Date = Date()
    var category: BiomarkerCategory = BiomarkerCategory.metabolic
    var minReference: Double?
    var maxReference: Double?
    var templateKey: String?

    init(
        id: UUID = UUID(),
        name: String,
        value: Double,
        unit: BiomarkerUnit,
        date: Date,
        category: BiomarkerCategory,
        minReference: Double? = nil,
        maxReference: Double? = nil,
        templateKey: String? = nil
    ) {
        self.id = id
        self.name = name
        self.value = value
        self.unit = unit
        self.date = date
        self.category = category
        self.minReference = minReference
        self.maxReference = maxReference
        self.templateKey = templateKey
    }
}
