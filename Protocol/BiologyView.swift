import SwiftUI
import SwiftData

struct BiologyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Biomarker.date, order: .reverse) private var biomarkers: [Biomarker]
    @Query(sort: \LabReport.importedAt, order: .reverse) private var reports: [LabReport]

    @State private var isAdding = false
    @State private var isImporting = false
    @State private var selectedReport: LabReport?
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        biologyOverviewCard
                        actionsCard

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
                        } else if groupedBiomarkers.isEmpty {
                            noResultsState
                        } else {
                            ForEach(groupedBiomarkers) { group in
                                VStack(spacing: 12) {
                                    HStack {
                                        Text(group.category.rawValue)
                                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                            .foregroundStyle(Color.textSecondary)
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
                        .foregroundStyle(Color.textSecondary)
                        .padding()
                }
            }
        }
    }

    private var noResultsState: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.neonCyan)

            Text("No matches")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Color.textPrimary)

            Text("Try a different name or category.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Color.textSecondary)
        }
        .glassCard()
    }

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.textTertiary)
                TextField("Search biomarkers", text: $searchText)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .foregroundStyle(Color.textPrimary)
            }
            .padding(10)
            .background(BevelInsetSurface(cornerRadius: 14))

            HStack(spacing: 10) {
                Button {
                    isImporting = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.badge.plus")
                        Text("Import PDF")
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                }
                .buttonStyle(SecondaryActionButtonStyle())

                Button {
                    isAdding = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                        Text("Add Result")
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                }
                .buttonStyle(SecondaryActionButtonStyle())
            }
        }
        .glassCard()
    }

    private var biologyOverviewCard: some View {
        let summaries = biomarkerSummaries
        let total = summaries.count
        let outOfRange = summaries.filter { $0.rangeState == .high || $0.rangeState == .low }.count
        let latestDate = biomarkers.first?.date

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Biology Overview")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(Color.neonCyan)
            }

            HStack(spacing: 12) {
                MetricTile(title: "Tracked", value: "\(total)", tint: Color.neonCyan)
                MetricTile(title: "Out of Range", value: "\(outOfRange)", tint: Color.neonAmber)
            }

            if let latestDate {
                Text("Latest result \(latestDate, style: .date)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .glassCard()
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 42, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.neonCyan)

            Text("No biomarkers yet")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.textPrimary)

            Text("Add your first lab result to begin tracking your biology.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .glassCard()
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(Color.textTertiary)
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private var biomarkerSummaries: [BiomarkerSummary] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = trimmed.isEmpty ? biomarkers : biomarkers.filter { biomarker in
            biomarker.name.localizedCaseInsensitiveContains(trimmed) ||
            biomarker.category.rawValue.localizedCaseInsensitiveContains(trimmed)
        }

        let grouped = Dictionary(grouping: filtered) { $0.templateKey ?? $0.name }
        let summaries = grouped.values.compactMap { values -> BiomarkerSummary? in
            let sorted = values.sorted(by: { $0.date > $1.date })
            guard let latest = sorted.first else { return nil }
            let previous = sorted.dropFirst().first
            return BiomarkerSummary(
                name: latest.name,
                templateKey: latest.templateKey,
                category: latest.category,
                latestValue: latest.value,
                unit: latest.unit,
                date: latest.date,
                minReference: latest.minReference,
                maxReference: latest.maxReference,
                previousValue: previous?.value
            )
        }
        return summaries.sorted { $0.name < $1.name }
    }

    private var groupedBiomarkers: [BiomarkerCategoryGroup] {
        let grouped = Dictionary(grouping: biomarkerSummaries) { $0.category }
        return grouped
            .map { category, items in
                BiomarkerCategoryGroup(category: category, items: items.sorted { $0.name < $1.name })
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
                    .foregroundStyle(Color.textPrimary)

                Text(biomarker.category.rawValue)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 6) {
                    Text("\(biomarker.value, specifier: "%.2f")")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text(biomarker.unit.rawValue)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Color.textSecondary)
                }

                Text(biomarker.date, style: .date)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
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
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Color.textPrimary)

                    if item.rangeState != .unknown {
                        RangeBadge(state: item.rangeState)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 6) {
                    Text("\(item.latestValue, specifier: "%.2f")")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text(item.unit.rawValue)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Color.textSecondary)
                }

                Text(item.date, style: .date)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.textSecondary)

                if let delta = item.delta {
                    DeltaBadge(delta: delta)
                }
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
                    .foregroundStyle(Color.textPrimary)

                Text(report.reportDate, style: .date)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
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
    let minReference: Double?
    let maxReference: Double?
    let previousValue: Double?

    var rangeState: BiomarkerRangeState {
        BiomarkerRangeState.evaluate(value: latestValue, min: minReference, max: maxReference)
    }

    var delta: Double? {
        guard let previousValue else { return nil }
        return latestValue - previousValue
    }
}

private struct BiomarkerCategoryGroup: Identifiable {
    let id = UUID()
    let category: BiomarkerCategory
    let items: [BiomarkerSummary]
}

private enum BiomarkerRangeState: String {
    case low = "Low"
    case high = "High"
    case inRange = "In Range"
    case unknown = "Unknown"

    static func evaluate(value: Double, min: Double?, max: Double?) -> BiomarkerRangeState {
        guard let min, let max else { return .unknown }
        if value < min { return .low }
        if value > max { return .high }
        return .inRange
    }

    var color: Color {
        switch self {
        case .low: return Color.neonAmber
        case .high: return Color.neonPink
        case .inRange: return Color.neonCyan
        case .unknown: return Color.textTertiary
        }
    }
}

private struct RangeBadge: View {
    let state: BiomarkerRangeState

    var body: some View {
        Text(state.rawValue)
            .font(.system(.caption2, design: .rounded).weight(.semibold))
            .foregroundStyle(state.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(BevelInsetSurface(cornerRadius: 10))
    }
}

private struct MetricTile: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(tint)
                    .frame(width: 6, height: 6)
                Text(title)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(BevelInsetSurface(cornerRadius: 16))
    }
}

private struct DeltaBadge: View {
    let delta: Double

    private var direction: DeltaDirection {
        if delta > 0 { return .up }
        if delta < 0 { return .down }
        return .flat
    }

    private var deltaText: String {
        delta.formatted(.number.sign(strategy: .always(includingZero: true)).precision(.fractionLength(2)))
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: direction.icon)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
            Text(deltaText)
                .font(.system(.caption2, design: .rounded).weight(.semibold))
        }
        .foregroundStyle(direction.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(BevelInsetSurface(cornerRadius: 10))
    }
}

private enum DeltaDirection {
    case up
    case down
    case flat

    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .flat: return "minus"
        }
    }

    var color: Color {
        switch self {
        case .up: return Color.neonCyan
        case .down: return Color.neonAmber
        case .flat: return Color.textTertiary
        }
    }
}

private struct BiomarkerTrendCard: View {
    let records: [Biomarker]
    let unit: BiomarkerUnit
    let minReference: Double?
    let maxReference: Double?

    private var values: [Double] {
        Array(records.suffix(30)).map { $0.value }
    }

    private var rangeText: String {
        guard let minReference, let maxReference else { return "—" }
        return "\(format(minReference, digits: 1)) - \(format(maxReference, digits: 1))"
    }

    var body: some View {
        let latestValue = values.last ?? 0

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Trend")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("Recent")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.textTertiary)
            }

            ZStack {
                BevelInsetSurface(cornerRadius: 16)
                if values.count >= 2 {
                    Sparkline(values: values)
                        .padding(14)
                } else {
                    Text("Add more results to unlock the trend.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .frame(height: 110)

            HStack(spacing: 12) {
                TrendMetric(title: "Latest", value: "\(format(latestValue, digits: 2)) \(unit.rawValue)")
                TrendMetric(title: "Range", value: rangeText)
            }
        }
        .glassCard()
    }

    private func format(_ value: Double, digits: Int) -> String {
        value.formatted(.number.precision(.fractionLength(digits)))
    }
}

private struct TrendMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Color.textSecondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(BevelInsetSurface(cornerRadius: 14))
    }
}

private struct Sparkline: View {
    let values: [Double]

    var body: some View {
        GeometryReader { proxy in
            let minValue = values.min() ?? 0
            let maxValue = values.max() ?? 1
            let range = max(maxValue - minValue, 0.0001)

            let points = values.enumerated().map { index, value -> CGPoint in
                let x = proxy.size.width * CGFloat(index) / CGFloat(max(values.count - 1, 1))
                let y = proxy.size.height * (1 - CGFloat((value - minValue) / range))
                return CGPoint(x: x, y: y)
            }

            Path { path in
                guard let first = points.first else { return }
                path.move(to: first)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
            .stroke(
                LinearGradient(
                    colors: [Color.neonCyan, Color.neonPink],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
        }
    }
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
        let sortedRecords = records.sorted(by: { $0.date < $1.date })
        let latestRecord = sortedRecords.last

        ZStack {
            AppBackground()
                .ignoresSafeArea()

            List {
                if let latest = latestRecord {
                    Section {
                        BiomarkerTrendCard(
                            records: sortedRecords,
                            unit: latest.unit,
                            minReference: latest.minReference,
                            maxReference: latest.maxReference
                        )
                        .listRowBackground(Color.clear)
                    }
                }

                Section {
                    ForEach(records) { record in
                        let state = BiomarkerRangeState.evaluate(
                            value: record.value,
                            min: record.minReference,
                            max: record.maxReference
                        )

                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    Text("\(record.value, specifier: "%.2f")")
                                        .font(.system(.headline, design: .rounded).weight(.semibold))
                                        .foregroundStyle(Color.textPrimary)
                                    Text(record.unit.rawValue)
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundStyle(Color.textSecondary)

                                    if state != .unknown {
                                        RangeBadge(state: state)
                                    }
                                }
                                Text(record.date, style: .date)
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(Color.textSecondary)
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
                } header: {
                    Text("History")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .tracking(1.2)
                        .foregroundStyle(Color.textTertiary)
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
            ZStack {
                AppBackground()
                    .ignoresSafeArea()

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
                .scrollContentBackground(.hidden)
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
                AppBackground()
                    .ignoresSafeArea()

                List(filteredTemplates) { template in
                    NavigationLink(value: template) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(Color.textPrimary)

                                Text(template.category.rawValue)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(Color.textSecondary)
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
        ZStack {
            AppBackground()
                .ignoresSafeArea()

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
            .scrollContentBackground(.hidden)
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
