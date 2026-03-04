import SwiftUI
import SwiftData

struct CheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]

    @State private var editorContext: CheckInEditorContext?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        overviewCard
                        todayCard

                        if checkIns.isEmpty {
                            emptyState
                        } else {
                            sectionHeader("Recent Check-ins", systemImage: "calendar")
                            ForEach(checkIns) { checkIn in
                                CheckInCard(checkIn: checkIn) {
                                    editorContext = CheckInEditorContext(checkIn: checkIn)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Check-in")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editorContext = CheckInEditorContext(checkIn: nil)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .accessibilityLabel("New Check-in")
                }
            }
            .sheet(item: $editorContext) { context in
                CheckInEditor(context: context) { draft in
                    saveCheckIn(draft, existing: context.checkIn)
                }
            }
        }
    }

    private var overviewCard: some View {
        let averages = weeklyAverages
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weekly Pulse")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("\(streakCount) day streak")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }

            HStack(spacing: 12) {
                RatingMetric(title: "Mood", value: averages.mood)
                RatingMetric(title: "Energy", value: averages.energy)
                RatingMetric(title: "Sleep", value: averages.sleep)
            }
        }
        .glassCard()
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let today = todayCheckIn {
                HStack {
                    Text("Today")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Button("Edit") {
                        editorContext = CheckInEditorContext(checkIn: today)
                    }
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.neonCyan)
                }

                HStack(spacing: 10) {
                    MiniRating(label: "Mood", value: today.mood)
                    MiniRating(label: "Energy", value: today.energy)
                    MiniRating(label: "Sleep", value: today.sleep)
                }
            } else {
                HStack {
                    Text("Log today")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                }
                Text("Capture how you feel today in under 30 seconds.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.textSecondary)

                Button {
                    editorContext = CheckInEditorContext(checkIn: nil)
                } label: {
                    HStack {
                        Text("New Check-in")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        Spacer()
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                }
                .buttonStyle(PrimaryActionButtonStyle(tint: Color.neonCyan))
            }
        }
        .glassCard()
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 42, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.neonCyan)

            Text("No check-ins yet")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.textPrimary)

            Text("Add a daily note to track how your body feels over time.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .glassCard()
    }

    private var todayCheckIn: DailyCheckIn? {
        let calendar = Calendar.current
        return checkIns.first { calendar.isDateInToday($0.date) }
    }

    private var weeklyAverages: CheckInAverages {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let recent = checkIns.filter { $0.date >= weekStart }
        guard !recent.isEmpty else { return CheckInAverages(mood: 0, energy: 0, sleep: 0) }

        let moodAvg = Double(recent.map { $0.mood }.reduce(0, +)) / Double(recent.count)
        let energyAvg = Double(recent.map { $0.energy }.reduce(0, +)) / Double(recent.count)
        let sleepAvg = Double(recent.map { $0.sleep }.reduce(0, +)) / Double(recent.count)

        return CheckInAverages(mood: moodAvg, energy: energyAvg, sleep: sleepAvg)
    }

    private var streakCount: Int {
        let calendar = Calendar.current
        let days = Set(checkIns.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var current = calendar.startOfDay(for: Date())

        while days.contains(current) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: current) else { break }
            current = previous
        }

        return streak
    }

    private func saveCheckIn(_ draft: CheckInDraft, existing: DailyCheckIn?) {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: draft.date)

        if let existing {
            existing.date = normalizedDate
            existing.mood = draft.mood
            existing.energy = draft.energy
            existing.sleep = draft.sleep
            existing.note = draft.note
            return
        }

        if let sameDay = checkIns.first(where: { calendar.isDate($0.date, inSameDayAs: normalizedDate) }) {
            sameDay.mood = draft.mood
            sameDay.energy = draft.energy
            sameDay.sleep = draft.sleep
            sameDay.note = draft.note
            return
        }

        let entry = DailyCheckIn(
            date: normalizedDate,
            mood: draft.mood,
            energy: draft.energy,
            sleep: draft.sleep,
            note: draft.note
        )
        modelContext.insert(entry)
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.neonCyan)
            Text(title.uppercased())
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(Color.textTertiary)
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

private struct CheckInEditorContext: Identifiable {
    let id = UUID()
    let checkIn: DailyCheckIn?
}

private struct CheckInDraft {
    let date: Date
    let mood: Int
    let energy: Int
    let sleep: Int
    let note: String
}

private struct CheckInAverages {
    let mood: Double
    let energy: Double
    let sleep: Double
}

private struct CheckInEditor: View {
    @Environment(\.dismiss) private var dismiss

    private let existing: DailyCheckIn?
    private let onSave: (CheckInDraft) -> Void

    @State private var date: Date
    @State private var mood: Int
    @State private var energy: Int
    @State private var sleep: Int
    @State private var note: String

    init(context: CheckInEditorContext, onSave: @escaping (CheckInDraft) -> Void) {
        self.existing = context.checkIn
        self.onSave = onSave
        _date = State(initialValue: context.checkIn?.date ?? Date())
        _mood = State(initialValue: context.checkIn?.mood ?? 3)
        _energy = State(initialValue: context.checkIn?.energy ?? 3)
        _sleep = State(initialValue: context.checkIn?.sleep ?? 3)
        _note = State(initialValue: context.checkIn?.note ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .font(.system(.headline, design: .rounded))
                                .foregroundStyle(Color.textPrimary)

                            DatePicker("", selection: $date, displayedComponents: [.date])
                                .labelsHidden()
                                .datePickerStyle(.graphical)
                                .tint(Color.neonCyan)
                        }
                        .glassCard()

                        RatingPicker(title: "Mood", icon: "face.smiling", value: $mood, tint: Color.neonCyan)
                        RatingPicker(title: "Energy", icon: "bolt.fill", value: $energy, tint: Color.neonAmber)
                        RatingPicker(title: "Sleep", icon: "moon.stars.fill", value: $sleep, tint: Color.neonPink)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.system(.headline, design: .rounded))
                                .foregroundStyle(Color.textPrimary)

                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $note)
                                    .frame(minHeight: 120)
                                    .scrollContentBackground(.hidden)
                                    .padding(10)
                                    .background(BevelInsetSurface(cornerRadius: 14))
                                    .foregroundStyle(Color.textPrimary)

                                if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text("Add a short note…")
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundStyle(Color.textTertiary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 18)
                                }
                            }
                        }
                        .glassCard()

                        Button {
                            let draft = CheckInDraft(date: date, mood: mood, energy: energy, sleep: sleep, note: note)
                            onSave(draft)
                            dismiss()
                        } label: {
                            HStack {
                                Text("Save Check-in")
                                    .font(.system(.headline, design: .rounded))
                                Spacer()
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                        }
                        .buttonStyle(PrimaryActionButtonStyle(tint: Color.neonCyan))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(existing == nil ? "New Check-in" : "Edit Check-in")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

private struct RatingPicker: View {
    let title: String
    let icon: String
    @Binding var value: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text(label)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { score in
                    Button {
                        value = score
                    } label: {
                        Text("\(score)")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(value == score ? Color.textPrimary : Color.textTertiary)
                            .frame(width: 36, height: 34)
                            .background(
                                ZStack {
                                    BevelInsetSurface(cornerRadius: 10)
                                    if value == score {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(tint.opacity(0.2))
                                    }
                                }
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .glassCard()
    }

    private var label: String {
        switch value {
        case 1: return "Low"
        case 2: return "Below"
        case 3: return "Steady"
        case 4: return "Good"
        default: return "High"
        }
    }
}

private struct CheckInCard: View {
    let checkIn: DailyCheckIn
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(checkIn.date, style: .date)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Button("Edit") {
                    onEdit()
                }
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.neonCyan)
            }

            HStack(spacing: 10) {
                MiniRating(label: "Mood", value: checkIn.mood)
                MiniRating(label: "Energy", value: checkIn.energy)
                MiniRating(label: "Sleep", value: checkIn.sleep)
            }

            if !checkIn.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(checkIn.note)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .glassCard()
    }
}

private struct RatingMetric: View {
    let title: String
    let value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Color.textSecondary)
            Text(valueText)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(BevelInsetSurface(cornerRadius: 16))
    }

    private var valueText: String {
        guard value > 0 else { return "—" }
        return value.formatted(.number.precision(.fractionLength(1)))
    }
}

private struct MiniRating: View {
    let label: String
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Color.textSecondary)
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { score in
                    Circle()
                        .fill(score <= value ? Color.neonCyan : Color.white.opacity(0.1))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(BevelInsetSurface(cornerRadius: 14))
    }
}

#Preview {
    CheckInView()
}
