import SwiftUI
import SwiftData
import PDFKit
import Vision
import UniformTypeIdentifiers

struct PDFImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var showImporter = false
    @State private var isParsing = false
    @State private var importedData: Data?
    @State private var importedFilename: String = ""
    @State private var extractedText: String = ""
    @State private var parsedItems: [ParsedLabResult] = []
    @State private var reportDate: Date = Date()
    @State private var parseError: String?
    @State private var showSaveError = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBackground.ignoresSafeArea()

                if isParsing {
                    ProgressView("Parsing PDF…")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.white)
                } else if let _ = importedData {
                    ImportReviewView(
                        reportDate: $reportDate,
                        parsedItems: $parsedItems,
                        onSave: saveImport
                    )
                } else {
                    emptyState
                }
            }
            .navigationTitle("Import PDF")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Select PDF") {
                        showImporter = true
                    }
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importPDF(from: url)
                case .failure(let error):
                    parseError = error.localizedDescription
                }
            }
            .alert("Import failed", isPresented: .constant(parseError != nil), actions: {
                Button("OK", role: .cancel) { parseError = nil }
            }, message: {
                Text(parseError ?? "Unknown error")
            })
            .alert("Cannot save", isPresented: $showSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please ensure all selected items have a value and a linked biomarker type.")
            }
            .onAppear {
                showImporter = true
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 42, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.neonCyan)

            Text("Import a lab report")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(.white)

            Text("Select a PDF to auto-detect biomarkers, values, units, and date.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .glassCard()
        .padding(.horizontal, 24)
    }

    private func importPDF(from url: URL) {
        let gotAccess = url.startAccessingSecurityScopedResource()
        defer {
            if gotAccess { url.stopAccessingSecurityScopedResource() }
        }

        do {
            isParsing = true
            importedData = try Data(contentsOf: url)
            importedFilename = url.lastPathComponent
        } catch {
            isParsing = false
            parseError = error.localizedDescription
        }

        guard importedData != nil else { return }
        Task {
            let text = await PDFTextExtractor.extractText(from: importedData)
            let parse = LabTextParser.parse(text)
            await MainActor.run {
                extractedText = text
                reportDate = parse.reportDate ?? Date()
                parsedItems = parse.items
                isParsing = false
            }
        }
    }

    private func saveImport() {
        let selectedItems = parsedItems.filter { $0.include }
        guard !selectedItems.isEmpty else {
            showSaveError = true
            return
        }
        let hasInvalid = selectedItems.contains { item in
            (item.selectedTemplate ?? item.matchedTemplate) == nil || item.parsedValue == nil
        }
        if hasInvalid {
            showSaveError = true
            return
        }

        let report = LabReport(
            title: importedFilename.isEmpty ? "Lab Report" : importedFilename,
            reportDate: reportDate,
            sourceFilename: importedFilename,
            rawText: extractedText.isEmpty ? nil : extractedText,
            pdfData: importedData
        )
        modelContext.insert(report)

        for item in selectedItems {
            guard let template = item.selectedTemplate ?? item.matchedTemplate else { continue }
            guard let value = item.parsedValue else { continue }

            let biomarker = Biomarker(
                name: template.name,
                value: value,
                unit: item.unit ?? template.defaultUnit,
                date: reportDate,
                category: template.category,
                minReference: template.minReference,
                maxReference: template.maxReference,
                templateKey: template.id,
                reportID: report.id
            )
            modelContext.insert(biomarker)
        }

        dismiss()
    }
}

private struct ImportReviewView: View {
    @Binding var reportDate: Date
    @Binding var parsedItems: [ParsedLabResult]
    let onSave: () -> Void

    @State private var editingIndex: Int?

    var body: some View {
        List {
            Section("Report") {
                DatePicker("Date", selection: $reportDate, displayedComponents: [.date])
            }

            Section("Matched") {
                ForEach(matchedItems.indices, id: \.self) { index in
                    itemRow(for: matchedItems[index])
                }
                if matchedItems.isEmpty {
                    Text("No matched biomarkers.")
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Section("Unmatched") {
                ForEach(unmatchedItems.indices, id: \.self) { index in
                    itemRow(for: unmatchedItems[index])
                }
                if unmatchedItems.isEmpty {
                    Text("Everything matched the catalog.")
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Section {
                Button("Save Selected Results") {
                    onSave()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.voidBackground)
        .sheet(isPresented: Binding(get: { editingIndex != nil }, set: { if !$0 { editingIndex = nil } })) {
            if let index = editingIndex {
                ImportItemEditor(item: binding(for: index))
            }
        }
    }

    private var matchedItems: [Int] {
        parsedItems.indices.filter { parsedItems[$0].matchedTemplate != nil }
    }

    private var unmatchedItems: [Int] {
        parsedItems.indices.filter { parsedItems[$0].matchedTemplate == nil }
    }

    private func itemRow(for index: Int) -> some View {
        let item = parsedItems[index]
        return HStack {
            Toggle("", isOn: binding(for: index).include)
                .labelsHidden()

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)

                Text(item.valueDisplay)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Button("Edit") {
                editingIndex = index
            }
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .foregroundStyle(Color.neonCyan)
        }
        .listRowBackground(Color.clear)
    }

    private func binding(for index: Int) -> Binding<ParsedLabResult> {
        Binding(
            get: { parsedItems[index] },
            set: { parsedItems[index] = $0 }
        )
    }

}

private struct ImportItemEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    @Binding var item: ParsedLabResult

    var body: some View {
        NavigationStack {
            Form {
                Section("Detected") {
                    Text(item.sourceLine)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Section("Biomarker") {
                    if let selected = item.selectedTemplate ?? item.matchedTemplate {
                        Text(selected.name)
                            .font(.system(.headline, design: .rounded))
                    } else {
                        Text("No match")
                            .foregroundStyle(.secondary)
                    }

                    NavigationLink("Choose from catalog") {
                        CatalogPicker(selectedTemplate: $item.selectedTemplate, searchText: $searchText)
                    }
                }

                Section("Result") {
                    TextField("Value", text: $item.valueText)
                        .keyboardType(.decimalPad)

                    Picker("Unit", selection: $item.unit) {
                        ForEach(BiomarkerUnit.allCases) { unit in
                            Text(unit.rawValue).tag(Optional(unit))
                        }
                    }
                }
            }
            .navigationTitle("Edit Result")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                if item.unit == nil {
                    item.unit = (item.selectedTemplate ?? item.matchedTemplate)?.defaultUnit
                }
            }
            .onChange(of: item.selectedTemplate) { _, newValue in
                if let template = newValue {
                    item.include = true
                    if item.unit == nil {
                        item.unit = template.defaultUnit
                    }
                }
            }
        }
    }
}

private struct CatalogPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTemplate: BiomarkerTemplate?
    @Binding var searchText: String

    private var filtered: [BiomarkerTemplate] {
        BiomarkerCatalog.search(searchText)
    }

    var body: some View {
        List(filtered) { template in
            Button {
                selectedTemplate = template
                dismiss()
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                    Text(template.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Choose Biomarker")
    }
}

struct ParsedLabResult: Identifiable, Hashable {
    let id: UUID = UUID()
    let sourceLine: String
    let rawName: String
    let matchedTemplate: BiomarkerTemplate?
    var selectedTemplate: BiomarkerTemplate?
    var valueText: String
    var unit: BiomarkerUnit?
    var include: Bool

    var displayName: String {
        (selectedTemplate ?? matchedTemplate)?.name ?? rawName
    }

    var valueDisplay: String {
        let unitText = unit?.rawValue ?? ""
        return "\(valueText) \(unitText)"
    }

    var parsedValue: Double? {
        NumberParser.parse(valueText)
    }
}

enum PDFTextExtractor {
    static func extractText(from data: Data?) async -> String {
        guard let data else { return "" }
        guard let document = PDFDocument(data: data) else { return "" }
        var text = ""
        for index in 0..<document.pageCount {
            if let page = document.page(at: index) {
                text.append(page.string ?? "")
                text.append("\n")
            }
        }

        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return await ocrText(from: document)
        }

        return text
    }

    private static func ocrText(from document: PDFDocument) async -> String {
        var combined = ""
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            let image = page.thumbnail(of: CGSize(width: 1800, height: 2400), for: .mediaBox)
            guard let cgImage = image.cgImage else { continue }

            let recognized = await recognizeText(in: cgImage)
            combined.append(recognized)
            combined.append("\n")
        }
        return combined
    }

    private static func recognizeText(in cgImage: CGImage) async -> String {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let strings = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: strings.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["hu-HU", "en-US"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: "")
            }
        }
    }
}

enum LabTextParser {
    struct ParseResult {
        let reportDate: Date?
        let items: [ParsedLabResult]
    }

    static func parse(_ text: String) -> ParseResult {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let reportDate = DateParser.detect(in: text)

        var results: [ParsedLabResult] = []
        for line in lines {
            let normalized = line.lowercased().replacingOccurrences(of: "µ", with: "u")
            let unit = UnitParser.detect(in: normalized)
            let unitRange = UnitParser.detectTokenRange(in: normalized)
            guard let valueText = NumberParser.bestNumber(in: normalized, unitRange: unitRange) else { continue }
            let template = BiomarkerCatalog.matchTemplate(in: line)
            guard unit != nil || template != nil else { continue }
            let name = template?.name ?? line
            let shouldInclude = template != nil

            results.append(
                ParsedLabResult(
                    sourceLine: line,
                    rawName: name,
                    matchedTemplate: template,
                    selectedTemplate: nil,
                    valueText: valueText,
                    unit: unit ?? template?.defaultUnit,
                    include: shouldInclude
                )
            )
        }

        return ParseResult(reportDate: reportDate, items: results)
    }
}

enum DateParser {
    private static let formatters: [DateFormatter] = {
        let locales = [
            Locale(identifier: "hu_HU"),
            Locale(identifier: "en_US_POSIX"),
            Locale.current
        ]

        let formats = [
            "yyyy.MM.dd",
            "yyyy.MM.dd.",
            "yyyy-MM-dd",
            "dd.MM.yyyy",
            "dd.MM.yyyy.",
            "dd/MM/yyyy"
        ]

        return locales.flatMap { locale in
            formats.map { format in
                let formatter = DateFormatter()
                formatter.locale = locale
                formatter.dateFormat = format
                return formatter
            }
        }
    }()

    static func detect(in text: String) -> Date? {
        let lines = text.components(separatedBy: .newlines)
        let keywords = ["dátum", "datum", "mintavétel", "vizsgálat", "eredmény", "date", "collected"]

        for line in lines {
            let lower = line.lowercased()
            guard keywords.contains(where: { lower.contains($0) }) else { continue }
            let candidates = extractDateStrings(from: line)
            for candidate in candidates {
                if let date = parse(candidate) {
                    return date
                }
            }
        }

        let candidates = extractDateStrings(from: text)
        for candidate in candidates {
            if let date = parse(candidate) {
                return date
            }
        }
        return nil
    }

    private static func parse(_ string: String) -> Date? {
        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }

    private static func extractDateStrings(from text: String) -> [String] {
        let patterns = [
            "\\b\\d{4}\\.\\d{1,2}\\.\\d{1,2}\\.?\\b",
            "\\b\\d{1,2}\\.\\d{1,2}\\.\\d{4}\\.?\\b",
            "\\b\\d{4}-\\d{1,2}-\\d{1,2}\\b",
            "\\b\\d{1,2}/\\d{1,2}/\\d{4}\\b"
        ]

        var results: [String] = []
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        results.append(String(text[range]))
                    }
                }
            }
        }
        return results
    }
}

enum UnitParser {
    private static let unitMap: [(String, BiomarkerUnit)] = [
        ("mg/dl", .mgdL),
        ("mg/l", .mgL),
        ("mmol/l", .mmoll),
        ("nmol/l", .nmoll),
        ("ng/ml", .ngmL),
        ("iu/l", .iul),
        ("pg/ml", .pgmL),
        ("miu/l", .miuL),
        ("uiu/ml", .uiuML),
        ("umol/l", .umolL),
        ("giga/l", .gigaL),
        ("tera/l", .teraL),
        ("g/l", .gL),
        ("fl", .fL),
        ("pg", .pg),
        ("mm/hour", .mmHour),
        ("ml/min/1.73m2", .mlMin173),
        ("leu/ul", .leuUL),
        ("l/l", .lL),
        ("%", .percent)
    ]

    static func detect(in line: String) -> BiomarkerUnit? {
        for (token, unit) in unitMap {
            if line.contains(token) {
                return unit
            }
        }
        return nil
    }

    static func detectTokenRange(in line: String) -> Range<String.Index>? {
        for (token, _) in unitMap {
            if let range = line.range(of: token) {
                return range
            }
        }
        return nil
    }
}

enum NumberParser {
    static func bestNumber(in text: String, unitRange: Range<String.Index>?) -> String? {
        let pattern = "[-+]?\\d{1,4}(?:[.,]\\d+)?"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        let ranges = matches.compactMap { Range($0.range, in: text) }
        guard !ranges.isEmpty else { return nil }

        if let unitRange {
            let unitIndex = text.distance(from: text.startIndex, to: unitRange.lowerBound)
            let best = ranges.min { lhs, rhs in
                let lhsIndex = text.distance(from: text.startIndex, to: lhs.lowerBound)
                let rhsIndex = text.distance(from: text.startIndex, to: rhs.lowerBound)
                return abs(lhsIndex - unitIndex) < abs(rhsIndex - unitIndex)
            }
            if let best {
                return String(text[best])
            }
        }

        return String(text[ranges[0]])
    }

    static func parse(_ text: String) -> Double? {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        if let number = formatter.number(from: text) {
            return number.doubleValue
        }
        let fallback = text.replacingOccurrences(of: ",", with: ".")
        return Double(fallback)
    }
}

struct PDFViewer: View {
    let data: Data

    var body: some View {
        PDFKitView(data: data)
            .ignoresSafeArea()
    }
}

struct PDFKitView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(data: data)
    }
}

#Preview {
    PDFImportView()
}
