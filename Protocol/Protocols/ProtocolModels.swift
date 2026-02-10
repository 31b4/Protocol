import Foundation
import SwiftData

enum ProtocolSlot: String, Codable, CaseIterable, Identifiable {
    case morning = "Morning"
    case daytime = "Day"
    case night = "Night"

    var id: String { rawValue }
}

enum SupplementUnit: String, Codable, CaseIterable, Identifiable {
    case mg = "mg"
    case mcg = "mcg"
    case g = "g"
    case iu = "IU"
    case ml = "mL"
    case pills = "pills"

    var id: String { rawValue }
}

enum ProtocolLogStatus: String, Codable, CaseIterable, Identifiable {
    case completed = "Completed"
    case missed = "Missed"
    case skipped = "Skipped"

    var id: String { rawValue }
}

@Model
final class ProtocolPlan {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var isActive: Bool = true

    @Relationship(deleteRule: .cascade, inverse: \ProtocolVersion.plan) var versions: [ProtocolVersion]?

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isActive: Bool = true,
        versions: [ProtocolVersion]? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isActive = isActive
        self.versions = versions
    }
}

@Model
final class ProtocolVersion {
    var id: UUID = UUID()
    var major: Int = 1
    var minor: Int = 0
    var createdAt: Date = Date()

    var plan: ProtocolPlan?

    @Relationship(deleteRule: .cascade, inverse: \ProtocolItem.version) var items: [ProtocolItem]?

    init(
        id: UUID = UUID(),
        major: Int,
        minor: Int,
        createdAt: Date = Date(),
        items: [ProtocolItem]? = nil,
        plan: ProtocolPlan? = nil
    ) {
        self.id = id
        self.major = major
        self.minor = minor
        self.createdAt = createdAt
        self.items = items
        self.plan = plan
    }

    var label: String {
        "v\(major).\(minor)"
    }
}

@Model
final class ProtocolItem {
    var id: UUID = UUID()
    var slot: ProtocolSlot = ProtocolSlot.morning
    var supplementName: String = ""
    var supplementKey: String?
    var amount: Double = 0
    var unit: SupplementUnit = SupplementUnit.mg
    var version: ProtocolVersion?

    init(
        id: UUID = UUID(),
        slot: ProtocolSlot,
        supplementName: String,
        supplementKey: String? = nil,
        amount: Double,
        unit: SupplementUnit,
        version: ProtocolVersion? = nil
    ) {
        self.id = id
        self.slot = slot
        self.supplementName = supplementName
        self.supplementKey = supplementKey
        self.amount = amount
        self.unit = unit
        self.version = version
    }
}

@Model
final class ProtocolLog {
    var id: UUID = UUID()
    var protocolID: UUID = UUID()
    var versionID: UUID = UUID()
    var date: Date = Date()
    var slot: ProtocolSlot = ProtocolSlot.morning
    var status: ProtocolLogStatus = ProtocolLogStatus.completed
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \ProtocolLogItem.log) var items: [ProtocolLogItem]?

    init(
        id: UUID = UUID(),
        protocolID: UUID,
        versionID: UUID,
        date: Date,
        slot: ProtocolSlot,
        status: ProtocolLogStatus,
        createdAt: Date = Date(),
        items: [ProtocolLogItem]? = nil
    ) {
        self.id = id
        self.protocolID = protocolID
        self.versionID = versionID
        self.date = date
        self.slot = slot
        self.status = status
        self.createdAt = createdAt
        self.items = items
    }
}

@Model
final class ProtocolLogItem {
    var id: UUID = UUID()
    var supplementName: String = ""
    var supplementKey: String?
    var amount: Double = 0
    var unit: SupplementUnit = SupplementUnit.mg
    var log: ProtocolLog?
    var healthKitSampleUUID: String?
    var healthKitTypeIdentifier: String?

    init(
        id: UUID = UUID(),
        supplementName: String,
        supplementKey: String? = nil,
        amount: Double,
        unit: SupplementUnit,
        log: ProtocolLog? = nil,
        healthKitSampleUUID: String? = nil,
        healthKitTypeIdentifier: String? = nil
    ) {
        self.id = id
        self.supplementName = supplementName
        self.supplementKey = supplementKey
        self.amount = amount
        self.unit = unit
        self.log = log
        self.healthKitSampleUUID = healthKitSampleUUID
        self.healthKitTypeIdentifier = healthKitTypeIdentifier
    }
}
