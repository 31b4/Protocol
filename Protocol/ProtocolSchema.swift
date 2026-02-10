import Foundation
import SwiftData

// MARK: - Schema V1 (Biology only)

enum ProtocolSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(1, 0, 0) }
    static var models: [any PersistentModel.Type] {
        [Biomarker.self, LabReport.self]
    }
}

// MARK: - Schema V3 (Biology + Protocols + Log Items)

enum ProtocolSchemaV3: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(3, 0, 0) }
    static var models: [any PersistentModel.Type] {
        [Biomarker.self, LabReport.self, ProtocolPlan.self, ProtocolVersion.self, ProtocolItem.self, ProtocolLog.self, ProtocolLogItem.self]
    }
}

// MARK: - Migration Plan

enum ProtocolMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ProtocolSchemaV1.self, ProtocolSchemaV3.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: ProtocolSchemaV1.self, toVersion: ProtocolSchemaV3.self)
        ]
    }
}
