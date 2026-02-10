import Foundation
import SwiftData

// MARK: - Schema V1 (Biology only)

enum ProtocolSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(1, 0, 0) }
    static var models: [any PersistentModel.Type] {
        [Biomarker.self, LabReport.self]
    }
}

// MARK: - Schema V4 (HealthKit log linkage)

enum ProtocolSchemaV4: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(4, 0, 0) }
    static var models: [any PersistentModel.Type] {
        [Biomarker.self, LabReport.self, ProtocolPlan.self, ProtocolVersion.self, ProtocolItem.self, ProtocolLog.self, ProtocolLogItem.self]
    }
}

// MARK: - Schema V6 (Log item supplement keys)

enum ProtocolSchemaV6: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(6, 0, 0) }
    static var models: [any PersistentModel.Type] {
        [Biomarker.self, LabReport.self, ProtocolPlan.self, ProtocolVersion.self, ProtocolItem.self, ProtocolLog.self, ProtocolLogItem.self]
    }
}

// MARK: - Migration Plan

enum ProtocolMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ProtocolSchemaV1.self, ProtocolSchemaV6.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: ProtocolSchemaV1.self, toVersion: ProtocolSchemaV6.self)
        ]
    }
}
