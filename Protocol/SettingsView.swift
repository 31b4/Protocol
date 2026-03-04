import SwiftUI
import HealthKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("healthkit_enabled") private var healthKitEnabled = false
    @State private var isRequesting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea()

                List {
                    Section("Health") {
                        Toggle(isOn: Binding(get: {
                            healthKitEnabled
                        }, set: { newValue in
                            if newValue {
                                requestHealthKit()
                            } else {
                                healthKitEnabled = false
                            }
                        })) {
                            Text("Sync with Apple Health")
                                .font(.system(.headline, design: .rounded))
                                .foregroundStyle(Color.textPrimary)
                        }

                        Text("We only request nutrition write access. Your data stays private.")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(Color.textSecondary)
                    }

                    Section("Nutrition Types") {
                        ForEach(HealthKitNutritionTypes.identifiers, id: \.self) { type in
                            Text(type.displayName)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(Color.textPrimary)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .overlay {
                if isRequesting {
                    ProgressView("Requesting access…")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                        .padding()
                        .background(BevelSurface(cornerRadius: 14))
                }
            }
            .alert("HealthKit Error", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }

    private func requestHealthKit() {
        isRequesting = true
        Task {
            do {
                try await HealthKitManager.shared.requestAuthorization()
                await MainActor.run {
                    healthKitEnabled = true
                    isRequesting = false
                }
            } catch {
                await MainActor.run {
                    healthKitEnabled = false
                    isRequesting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

private extension HKQuantityTypeIdentifier {
    var displayName: String {
        switch self {
        case .dietaryEnergyConsumed: return "Energy"
        case .dietaryProtein: return "Protein"
        case .dietaryCarbohydrates: return "Carbohydrates"
        case .dietaryFatTotal: return "Total Fat"
        case .dietaryFatSaturated: return "Saturated Fat"
        case .dietaryFatMonounsaturated: return "Monounsaturated Fat"
        case .dietaryFatPolyunsaturated: return "Polyunsaturated Fat"
        case .dietaryCholesterol: return "Cholesterol"
        case .dietaryFiber: return "Fiber"
        case .dietarySugar: return "Sugar"
        case .dietarySodium: return "Sodium"
        case .dietaryPotassium: return "Potassium"
        case .dietaryCalcium: return "Calcium"
        case .dietaryIron: return "Iron"
        case .dietaryVitaminA: return "Vitamin A"
        case .dietaryVitaminB6: return "Vitamin B6"
        case .dietaryVitaminB12: return "Vitamin B12"
        case .dietaryVitaminC: return "Vitamin C"
        case .dietaryVitaminD: return "Vitamin D"
        case .dietaryVitaminE: return "Vitamin E"
        case .dietaryVitaminK: return "Vitamin K"
        case .dietaryFolate: return "Folate"
        case .dietaryBiotin: return "Biotin"
        case .dietaryNiacin: return "Niacin"
        case .dietaryPantothenicAcid: return "Pantothenic Acid"
        case .dietaryRiboflavin: return "Riboflavin"
        case .dietaryThiamin: return "Thiamin"
        case .dietaryMagnesium: return "Magnesium"
        case .dietaryPhosphorus: return "Phosphorus"
        case .dietaryZinc: return "Zinc"
        case .dietaryCopper: return "Copper"
        case .dietaryManganese: return "Manganese"
        case .dietarySelenium: return "Selenium"
        case .dietaryChromium: return "Chromium"
        case .dietaryMolybdenum: return "Molybdenum"
        case .dietaryIodine: return "Iodine"
        case .dietaryWater: return "Water"
        default: return "Other"
        }
    }
}

#Preview {
    SettingsView()
}
