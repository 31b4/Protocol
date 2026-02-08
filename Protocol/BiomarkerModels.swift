import Foundation
import SwiftData

enum BiomarkerUnit: String, Codable, CaseIterable, Identifiable {
    case mgdL = "mg/dL"
    case mgL = "mg/L"
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
    var reportID: UUID?

    init(
        id: UUID = UUID(),
        name: String,
        value: Double,
        unit: BiomarkerUnit,
        date: Date,
        category: BiomarkerCategory,
        minReference: Double? = nil,
        maxReference: Double? = nil,
        templateKey: String? = nil,
        reportID: UUID? = nil
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
        self.reportID = reportID
    }
}

@Model
final class LabReport {
    var id: UUID = UUID()
    var title: String = ""
    var reportDate: Date = Date()
    var importedAt: Date = Date()
    var sourceFilename: String = ""
    var rawText: String?

    @Attribute(.externalStorage) var pdfData: Data?

    init(
        id: UUID = UUID(),
        title: String,
        reportDate: Date,
        importedAt: Date = Date(),
        sourceFilename: String,
        rawText: String? = nil,
        pdfData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.reportDate = reportDate
        self.importedAt = importedAt
        self.sourceFilename = sourceFilename
        self.rawText = rawText
        self.pdfData = pdfData
    }
}
