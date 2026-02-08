import SwiftUI
import SwiftData

struct BiologyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Biomarker.date, order: .reverse) private var biomarkers: [Biomarker]
    @Query(sort: \LabReport.importedAt, order: .reverse) private var reports: [LabReport]

    @State private var isAdding = false
    @State private var isImporting = false
    @State private var selectedReport: LabReport?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBackground.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        Button {
                            isImporting = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.badge.plus")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                Text("Import PDF")
                                    .font(.system(.headline, design: .rounded).weight(.semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                        }
                        .glassCard()

                        if reports.isEmpty == false {
                            sectionHeader("Saved Reports")
                            ForEach(reports) { report in
                                LabReportRow(report: report) {
                                    selectedReport = report
                                }
                            }
                        }

                        sectionHeader("Tracked Biomarkers")

                        if biomarkers.isEmpty {
                            emptyState
                        } else {
                            ForEach(groupedBiomarkers) { group in
                                VStack(spacing: 12) {
                                    HStack {
                                        Text(group.category.rawValue)
                                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.7))
                                        Spacer()
                                    }
                                    ForEach(group.items) { item in
                                        NavigationLink {
                                            BiomarkerDetailView(
                                                title: item.name,
                                                templateKey: item.templateKey,
                                                category: item.category
                                            )
                                        } label: {
                                            BiomarkerSummaryRow(item: item)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
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
            .sheet(isPresented: $isImporting) {
                PDFImportView()
            }
            .sheet(isPresented: Binding(get: { selectedReport != nil }, set: { if !$0 { selectedReport = nil } })) {
                if let report = selectedReport, let data = report.pdfData {
                    PDFViewer(data: data)
                } else {
                    Text("PDF not available")
                        .foregroundStyle(.white)
                        .padding()
                }
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
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private var groupedBiomarkers: [BiomarkerCategoryGroup] {
        let grouped = Dictionary(grouping: biomarkers) { $0.category }
        return grouped
            .map { category, items in
                let byName = Dictionary(grouping: items) { $0.templateKey ?? $0.name }
                let summaries = byName.values.compactMap { values -> BiomarkerSummary? in
                    guard let latest = values.sorted(by: { $0.date > $1.date }).first else { return nil }
                    return BiomarkerSummary(
                        name: latest.name,
                        templateKey: latest.templateKey,
                        category: latest.category,
                        latestValue: latest.value,
                        unit: latest.unit,
                        date: latest.date
                    )
                }
                .sorted { $0.name < $1.name }

                return BiomarkerCategoryGroup(category: category, items: summaries)
            }
            .sorted { $0.category.rawValue < $1.category.rawValue }
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
                HStack(spacing: 6) {
                    Text("\(biomarker.value, specifier: "%.2f")")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white)
                    Text(biomarker.unit.rawValue)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Text(biomarker.date, style: .date)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .glassCard()
    }
}

private struct BiomarkerSummaryRow: View {
    let item: BiomarkerSummary

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 6) {
                    Text("\(item.latestValue, specifier: "%.2f")")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white)
                    Text(item.unit.rawValue)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Text(item.date, style: .date)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .glassCard()
    }
}

private struct LabReportRow: View {
    let report: LabReport
    let onOpen: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(report.title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)

                Text(report.reportDate, style: .date)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Button("View") {
                onOpen()
            }
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .foregroundStyle(Color.neonCyan)
        }
        .glassCard()
    }
}

private struct BiomarkerSummary: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let templateKey: String?
    let category: BiomarkerCategory
    let latestValue: Double
    let unit: BiomarkerUnit
    let date: Date
}

private struct BiomarkerCategoryGroup: Identifiable {
    let id = UUID()
    let category: BiomarkerCategory
    let items: [BiomarkerSummary]
}

private struct BiomarkerDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var records: [Biomarker]

    @State private var selectedBiomarkerForEdit: Biomarker?

    private let title: String
    private let templateKey: String?
    private let category: BiomarkerCategory

    init(title: String, templateKey: String?, category: BiomarkerCategory) {
        self.title = title
        self.templateKey = templateKey
        self.category = category

        if let key = templateKey {
            _records = Query(
                filter: #Predicate<Biomarker> { $0.templateKey == key },
                sort: [SortDescriptor(\Biomarker.date, order: .reverse)]
            )
        } else {
            _records = Query(
                filter: #Predicate<Biomarker> { $0.name == title && $0.category == category },
                sort: [SortDescriptor(\Biomarker.date, order: .reverse)]
            )
        }
    }

    var body: some View {
        ZStack {
            Color.voidBackground.ignoresSafeArea()

            List {
                ForEach(records) { record in
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text("\(record.value, specifier: "%.2f")")
                                    .font(.system(.headline, design: .rounded).weight(.semibold))
                                    .foregroundStyle(.white)
                                Text(record.unit.rawValue)
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            Text(record.date, style: .date)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    .contextMenu {
                        Button("Edit") { selectedBiomarkerForEdit = record }
                        Button("Delete", role: .destructive) {
                            modelContext.delete(record)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(title)
        .sheet(item: $selectedBiomarkerForEdit) { biomarker in
            EditBiomarkerSheet(biomarker: biomarker)
        }
    }
}

private struct EditBiomarkerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var biomarker: Biomarker

    @State private var valueText: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedUnit: BiomarkerUnit = .mgdL
    @State private var showInvalidValueAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Biomarker") {
                    Text(biomarker.name)
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
            }
            .navigationTitle("Edit Result")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear {
                valueText = String(format: "%.2f", biomarker.value)
                selectedDate = biomarker.date
                selectedUnit = biomarker.unit
            }
            .alert("Invalid value", isPresented: $showInvalidValueAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Enter a numeric value using your locale format.")
            }
        }
    }

    private func save() {
        guard let value = NumberParser.parse(valueText) else {
            showInvalidValueAlert = true
            return
        }
        biomarker.value = value
        biomarker.unit = selectedUnit
        biomarker.date = selectedDate
        dismiss()
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
