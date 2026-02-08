import SwiftUI
import SwiftData

struct BiologyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Biomarker.date, order: .reverse) private var biomarkers: [Biomarker]

    @State private var isAdding = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBackground.ignoresSafeArea()

                if biomarkers.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(biomarkers) { biomarker in
                                BiomarkerRow(biomarker: biomarker)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Biology")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAdding = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .accessibilityLabel("Add Result")
                }
            }
            .sheet(isPresented: $isAdding) {
                AddBiomarkerSheet()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 42, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.neonCyan)

            Text("No biomarkers yet")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(.white)

            Text("Add your first lab result to begin tracking your biology.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .glassCard()
        .padding(.horizontal, 24)
    }
}

private struct BiomarkerRow: View {
    let biomarker: Biomarker

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(biomarker.name)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)

                Text(biomarker.category.rawValue)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("\(biomarker.value, specifier: "%.2f") \(biomarker.unit.rawValue)")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)

                Text(biomarker.date, style: .date)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .glassCard()
    }
}

private struct AddBiomarkerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var valueText = ""
    @State private var selectedUnit: BiomarkerUnit = .mgdL
    @State private var selectedDate = Date()
    @State private var showInvalidValueAlert = false

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        return formatter
    }()

    private var filteredTemplates: [BiomarkerTemplate] {
        BiomarkerCatalog.search(searchText)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBackground.ignoresSafeArea()

                List(filteredTemplates) { template in
                    NavigationLink(value: template) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(.white)

                                Text(template.category.rawValue)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.6))
                            }

                            Spacer()

                            Text(template.defaultUnit.rawValue)
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundStyle(Color.neonCyan)
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search biomarkers")
                .navigationTitle("Add Result")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
                .navigationDestination(for: BiomarkerTemplate.self) { template in
                    entryForm(for: template)
                }
            }
        }
    }

    @ViewBuilder
    private func entryForm(for template: BiomarkerTemplate) -> some View {
        Form {
            Section("Biomarker") {
                Text(template.name)
                    .font(.system(.headline, design: .rounded))
            }

            Section("Result") {
                TextField("Value", text: $valueText)
                    .keyboardType(.decimalPad)

                Picker("Unit", selection: $selectedUnit) {
                    ForEach(BiomarkerUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }

                DatePicker("Date", selection: $selectedDate, displayedComponents: [.date])
            }

            Section {
                Button("Save Result") {
                    selectedUnit = selectedUnit
                    guard let number = Self.numberFormatter.number(from: valueText) else {
                        showInvalidValueAlert = true
                        return
                    }
                    let value = number.doubleValue

                    let biomarker = Biomarker(
                        name: template.name,
                        value: value,
                        unit: selectedUnit,
                        date: selectedDate,
                        category: template.category,
                        minReference: template.minReference,
                        maxReference: template.maxReference,
                        templateKey: template.id
                    )
                    modelContext.insert(biomarker)
                    dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("New Result")
        .onAppear {
            selectedUnit = template.defaultUnit
        }
        .alert("Invalid value", isPresented: $showInvalidValueAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Enter a numeric value using your locale format.")
        }
    }
}

#Preview {
    BiologyView()
}
