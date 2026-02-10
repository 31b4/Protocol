import Foundation
import HealthKit
import Combine

final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    @Published var isAuthorized: Bool = false

    private init() {}

    func isAvailable() -> Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard isAvailable() else {
            throw HealthKitError.notAvailable
        }

        let writeTypes = HealthKitNutritionTypes.writeTypes
        guard !writeTypes.isEmpty else {
            throw HealthKitError.missingTypes
        }

        try await healthStore.requestAuthorization(toShare: writeTypes, read: [])
        await MainActor.run {
            self.isAuthorized = true
        }
    }

    func saveNutritionSamples(items: [ProtocolLogItem], date: Date) async throws {
        guard isAvailable() else { throw HealthKitError.notAvailable }

        let now = Date()
        let timestamp = DateBuilder.combine(date: date, time: now)

        var pairs: [(ProtocolLogItem, HKQuantitySample, HKQuantityTypeIdentifier)] = []
        for item in items {
            guard let identifier = HealthKitNutritionTypes.identifier(for: item) else { continue }
            guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else { continue }
            guard let resolved = HealthKitNutritionTypes.resolvedQuantity(for: item, identifier: identifier) else { continue }
            let sample = HKQuantitySample(type: quantityType, quantity: resolved.quantity, start: timestamp, end: timestamp)
            pairs.append((item, sample, identifier))
        }

        if pairs.isEmpty { return }

        let samples = pairs.map { $0.1 }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.save(samples) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    for (item, sample, identifier) in pairs {
                        item.healthKitSampleUUID = sample.uuid.uuidString
                        item.healthKitTypeIdentifier = identifier.rawValue
                    }
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: HealthKitError.saveFailed)
                }
            }
        }
    }

    func deleteSamples(uuids: [String]) async throws {
        guard isAvailable() else { throw HealthKitError.notAvailable }
        let ids = uuids.compactMap { UUID(uuidString: $0) }
        guard !ids.isEmpty else { return }
        let predicate = NSPredicate(format: "UUID IN %@", ids)

        let allTypes = HealthKitNutritionTypes.identifiers.compactMap { HKObjectType.quantityType(forIdentifier: $0) }
        for type in allTypes {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                healthStore.deleteObjects(of: type, predicate: predicate) { success, _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if success {
                        continuation.resume(returning: ())
                    } else {
                        continuation.resume(throwing: HealthKitError.deleteFailed)
                    }
                }
            }
        }
    }

    func deleteSamples(items: [ProtocolLogItem]) async throws {
        guard isAvailable() else { throw HealthKitError.notAvailable }

        let grouped = Dictionary(grouping: items.compactMap { item -> (String, UUID)? in
            guard let raw = item.healthKitTypeIdentifier,
                  let uuidString = item.healthKitSampleUUID,
                  let uuid = UUID(uuidString: uuidString) else { return nil }
            return (raw, uuid)
        }, by: { $0.0 })

        for (rawIdentifier, tuples) in grouped {
            let typeIdentifier = HKQuantityTypeIdentifier(rawValue: rawIdentifier)
            guard let type = HKObjectType.quantityType(forIdentifier: typeIdentifier) else { continue }
            let ids = tuples.map { $0.1 }
            let predicate = NSPredicate(format: "UUID IN %@", ids)
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                healthStore.deleteObjects(of: type, predicate: predicate) { success, _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if success {
                        continuation.resume(returning: ())
                    } else {
                        continuation.resume(throwing: HealthKitError.deleteFailed)
                    }
                }
            }
        }
    }
}

enum HealthKitError: Error {
    case notAvailable
    case missingTypes
    case saveFailed
    case deleteFailed
}

enum HealthKitNutritionTypes {
    static let identifiers: [HKQuantityTypeIdentifier] = [
        .dietaryEnergyConsumed,
        .dietaryProtein,
        .dietaryCarbohydrates,
        .dietaryFatTotal,
        .dietaryFatSaturated,
        .dietaryFatMonounsaturated,
        .dietaryFatPolyunsaturated,
        .dietaryCholesterol,
        .dietaryFiber,
        .dietarySugar,
        .dietarySodium,
        .dietaryPotassium,
        .dietaryCalcium,
        .dietaryIron,
        .dietaryVitaminA,
        .dietaryVitaminB6,
        .dietaryVitaminB12,
        .dietaryVitaminC,
        .dietaryVitaminD,
        .dietaryVitaminE,
        .dietaryVitaminK,
        .dietaryFolate,
        .dietaryBiotin,
        .dietaryNiacin,
        .dietaryPantothenicAcid,
        .dietaryRiboflavin,
        .dietaryThiamin,
        .dietaryMagnesium,
        .dietaryPhosphorus,
        .dietaryZinc,
        .dietaryCopper,
        .dietaryManganese,
        .dietarySelenium,
        .dietaryChromium,
        .dietaryMolybdenum,
        .dietaryIodine,
        .dietaryWater
    ]

    static var writeTypes: Set<HKSampleType> {
        Set(identifiers.compactMap { HKObjectType.quantityType(forIdentifier: $0) })
    }

    static func identifier(for item: ProtocolLogItem) -> HKQuantityTypeIdentifier? {
        if let key = item.supplementKey?.lowercased(),
           let mapped = NutritionMapping.keyMap[key] {
            return mapped
        }
        return NutritionMapping.nameMap[item.supplementName.lowercased()]
    }

    static func hkUnit(for unit: SupplementUnit) -> HKUnit? {
        switch unit {
        case .mg:
            return HKUnit.gramUnit(with: .milli)
        case .mcg:
            return HKUnit.gramUnit(with: .micro)
        case .g:
            return HKUnit.gram()
        case .iu:
            return nil
        case .ml:
            return HKUnit.literUnit(with: .milli)
        case .pills:
            return HKUnit.count()
        }
    }

    struct ResolvedQuantity {
        let quantity: HKQuantity
    }

    static func resolvedQuantity(for item: ProtocolLogItem, identifier: HKQuantityTypeIdentifier) -> ResolvedQuantity? {
        switch item.unit {
        case .iu:
            guard let converted = convertIU(amount: item.amount, identifier: identifier) else { return nil }
            let unit = converted.unit
            let quantity = HKQuantity(unit: unit, doubleValue: converted.value)
            return ResolvedQuantity(quantity: quantity)
        default:
            guard let unit = hkUnit(for: item.unit) else { return nil }
            let quantity = HKQuantity(unit: unit, doubleValue: item.amount)
            return ResolvedQuantity(quantity: quantity)
        }
    }

    private static func convertIU(amount: Double, identifier: HKQuantityTypeIdentifier) -> (value: Double, unit: HKUnit)? {
        switch identifier {
        case .dietaryVitaminD:
            // 1 IU = 0.025 mcg vitamin D
            return (amount * 0.025, HKUnit.gramUnit(with: .micro))
        case .dietaryVitaminA:
            // 1 IU = 0.3 mcg retinol
            return (amount * 0.3, HKUnit.gramUnit(with: .micro))
        case .dietaryVitaminE:
            // 1 IU = 0.67 mg d-alpha tocopherol
            return (amount * 0.67, HKUnit.gramUnit(with: .milli))
        default:
            return nil
        }
    }
}

enum NutritionMapping {
    static let keyMap: [String: HKQuantityTypeIdentifier] = [
        "vitamin_d3": .dietaryVitaminD,
        "vitamin_k2": .dietaryVitaminK,
        "vitamin_c": .dietaryVitaminC,
        "vitamin_b12": .dietaryVitaminB12,
        "folate": .dietaryFolate,
        "vitamin_a": .dietaryVitaminA,
        "vitamin_e": .dietaryVitaminE,
        "vitamin_b6": .dietaryVitaminB6,
        "biotin": .dietaryBiotin,
        "thiamine": .dietaryThiamin,
        "riboflavin": .dietaryRiboflavin,
        "niacin": .dietaryNiacin,
        "pantothenic": .dietaryPantothenicAcid,
        "magnesium_glycinate": .dietaryMagnesium,
        "zinc": .dietaryZinc,
        "selenium": .dietarySelenium,
        "iodine": .dietaryIodine,
        "calcium": .dietaryCalcium,
        "potassium": .dietaryPotassium,
        "iron": .dietaryIron,
        "copper": .dietaryCopper,
        "chromium": .dietaryChromium,
        "manganese": .dietaryManganese,
        "boron": .dietaryMolybdenum,
        "water": .dietaryWater
    ]

    static let nameMap: [String: HKQuantityTypeIdentifier] = [
        "vitamin d3": .dietaryVitaminD,
        "vitamin d": .dietaryVitaminD,
        "vitamin k2": .dietaryVitaminK,
        "vitamin c": .dietaryVitaminC,
        "vitamin b12": .dietaryVitaminB12,
        "folate": .dietaryFolate,
        "vitamin a": .dietaryVitaminA,
        "vitamin e": .dietaryVitaminE,
        "vitamin b6": .dietaryVitaminB6,
        "biotin": .dietaryBiotin,
        "thiamine (b1)": .dietaryThiamin,
        "riboflavin (b2)": .dietaryRiboflavin,
        "niacin": .dietaryNiacin,
        "pantothenic acid (b5)": .dietaryPantothenicAcid,
        "magnesium glycinate": .dietaryMagnesium,
        "magnesium": .dietaryMagnesium,
        "zinc": .dietaryZinc,
        "selenium": .dietarySelenium,
        "iodine": .dietaryIodine,
        "calcium": .dietaryCalcium,
        "potassium": .dietaryPotassium,
        "iron": .dietaryIron,
        "copper": .dietaryCopper,
        "chromium": .dietaryChromium,
        "manganese": .dietaryManganese,
        "boron": .dietaryMolybdenum,
        "water": .dietaryWater
    ]
}

enum DateBuilder {
    static func combine(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        dateComponents.second = timeComponents.second
        return calendar.date(from: dateComponents) ?? date
    }
}
