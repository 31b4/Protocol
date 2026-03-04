import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query(sort: \ProtocolPlan.updatedAt, order: .reverse) private var protocols: [ProtocolPlan]
    @Query(sort: \ProtocolLog.createdAt, order: .reverse) private var logs: [ProtocolLog]
    @Query(sort: \Biomarker.date, order: .reverse) private var biomarkers: [Biomarker]
    @Query(sort: \DailyCheckIn.date, order: .reverse) private var checkIns: [DailyCheckIn]

    var body: some View {
        ZStack {
            AppBackground()
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 16) {
                    snapshotCard
                    adherenceTrendCard
                    protocolConsistencyCard
                    signalsCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Insights")
    }

    private var snapshotCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Snapshot")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("Last 7 days")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }

            HStack(spacing: 12) {
                InsightMetricTile(title: "Adherence", value: percentageText(weeklyAdherence))
                InsightMetricTile(title: "In Range", value: percentageText(biomarkerInRange))
                InsightMetricTile(title: "Check-ins", value: checkInCountText)
            }
        }
        .glassCard()
    }

    private var adherenceTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Adherence Trend")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("Resolved slots")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }

            AdherenceBarChart(days: adherenceDays)
                .frame(height: 120)
        }
        .glassCard()
    }

    private var protocolConsistencyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Consistency")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("Current streak: \(streakCount) days")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }

            if let best = bestProtocol {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(best.plan.name)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(Color.textPrimary)
                        Text("Top protocol")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()

                    Text(percentageText(best.ratio))
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(BevelInsetSurface(cornerRadius: 12))
                }
            } else {
                Text("No protocol data yet.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .glassCard()
    }

    private var signalsCard: some View {
        let averages = checkInAverages
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Signals")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("Weekly average")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }

            HStack(spacing: 12) {
                InsightMetricTile(title: "Mood", value: averages.mood)
                InsightMetricTile(title: "Energy", value: averages.energy)
                InsightMetricTile(title: "Sleep", value: averages.sleep)
            }
        }
        .glassCard()
    }

    private var activeProtocols: [ProtocolPlan] {
        protocols.filter { $0.isActive }
    }

    private var adherenceDays: [AdherenceDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let requirements = requiredSlots(for: activeProtocols)

        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let ratio = adherenceRatio(for: date, requirements: requirements)
            return AdherenceDay(date: date, ratio: ratio)
        }
    }

    private var weeklyAdherence: Double {
        let ratios = adherenceDays.map { $0.ratio }
        guard !ratios.isEmpty else { return 0 }
        return ratios.reduce(0, +) / Double(ratios.count)
    }

    private var bestProtocol: ProtocolConsistency? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let windowStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today

        let results = activeProtocols.compactMap { plan -> ProtocolConsistency? in
            guard let version = plan.currentVersion else { return nil }
            let slots = ProtocolSlot.allCases.filter { slot in
                (version.items ?? []).contains { $0.slot == slot }
            }
            guard !slots.isEmpty else { return nil }

            var resolved = 0
            var total = 0
            for offset in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
                guard day >= windowStart else { continue }

                for slot in slots {
                    total += 1
                    if let log = logs.first(where: { $0.protocolID == plan.id && $0.slot == slot && calendar.isDate($0.date, inSameDayAs: day) }) {
                        if log.status == .completed || log.status == .skipped {
                            resolved += 1
                        }
                    }
                }
            }

            guard total > 0 else { return nil }
            return ProtocolConsistency(plan: plan, ratio: Double(resolved) / Double(total))
        }

        return results.sorted(by: { $0.ratio > $1.ratio }).first
    }

    private var streakCount: Int {
        let calendar = Calendar.current
        let requirements = requiredSlots(for: activeProtocols)
        guard !requirements.isEmpty else { return 0 }

        var streak = 0
        var current = calendar.startOfDay(for: Date())

        while streak < 60 {
            let ratio = adherenceRatio(for: current, requirements: requirements)
            if ratio < 1 { break }
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: current) else { break }
            current = previous
        }

        return streak
    }

    private var biomarkerInRange: Double {
        let grouped = Dictionary(grouping: biomarkers) { $0.templateKey ?? $0.name }
        let latest = grouped.values.compactMap { values -> Biomarker? in
            values.sorted(by: { $0.date > $1.date }).first
        }

        let considered = latest.filter { $0.minReference != nil && $0.maxReference != nil }
        guard !considered.isEmpty else { return 0 }

        let inRange = considered.filter { biomarker in
            guard let min = biomarker.minReference, let max = biomarker.maxReference else { return false }
            return biomarker.value >= min && biomarker.value <= max
        }

        return Double(inRange.count) / Double(considered.count)
    }

    private var checkInAverages: InsightAverages {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let recent = checkIns.filter { $0.date >= weekStart }
        guard !recent.isEmpty else { return InsightAverages(mood: "—", energy: "—", sleep: "—") }

        let moodAvg = Double(recent.map { $0.mood }.reduce(0, +)) / Double(recent.count)
        let energyAvg = Double(recent.map { $0.energy }.reduce(0, +)) / Double(recent.count)
        let sleepAvg = Double(recent.map { $0.sleep }.reduce(0, +)) / Double(recent.count)

        return InsightAverages(
            mood: moodAvg.formatted(.number.precision(.fractionLength(1))),
            energy: energyAvg.formatted(.number.precision(.fractionLength(1))),
            sleep: sleepAvg.formatted(.number.precision(.fractionLength(1)))
        )
    }

    private var checkInCountText: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let count = checkIns.filter { $0.date >= weekStart }.count
        return "\(count)"
    }

    private func requiredSlots(for plans: [ProtocolPlan]) -> [SlotRequirement] {
        var requirements: [SlotRequirement] = []
        for plan in plans {
            guard let version = plan.currentVersion else { continue }
            for slot in ProtocolSlot.allCases {
                if (version.items ?? []).contains(where: { $0.slot == slot }) {
                    requirements.append(SlotRequirement(planID: plan.id, slot: slot))
                }
            }
        }
        return requirements
    }

    private func adherenceRatio(for date: Date, requirements: [SlotRequirement]) -> Double {
        guard !requirements.isEmpty else { return 0 }
        let calendar = Calendar.current
        let dayLogs = logs.filter { log in
            calendar.isDate(log.date, inSameDayAs: date) &&
            requirements.contains(where: { $0.planID == log.protocolID && $0.slot == log.slot })
        }

        var resolved = 0
        for requirement in requirements {
            if let log = dayLogs.first(where: { $0.protocolID == requirement.planID && $0.slot == requirement.slot }) {
                if log.status == .completed || log.status == .skipped {
                    resolved += 1
                }
            }
        }

        return Double(resolved) / Double(requirements.count)
    }

    private func percentageText(_ value: Double) -> String {
        guard value > 0 else { return "—" }
        return value.formatted(.percent.precision(.fractionLength(0)))
    }
}

private struct SlotRequirement: Hashable {
    let planID: UUID
    let slot: ProtocolSlot
}

private struct ProtocolConsistency {
    let plan: ProtocolPlan
    let ratio: Double
}

private struct InsightMetricTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Color.textSecondary)
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(BevelInsetSurface(cornerRadius: 16))
    }
}

private struct AdherenceDay: Identifiable {
    let id = UUID()
    let date: Date
    let ratio: Double

    var label: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
}

private struct AdherenceBarChart: View {
    let days: [AdherenceDay]

    var body: some View {
        GeometryReader { proxy in
            let maxHeight = proxy.size.height - 18
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(days) { day in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(barGradient(for: day.ratio))
                            .frame(height: maxHeight * max(day.ratio, 0.04))
                        Text(day.label)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(Color.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: proxy.size.height, alignment: .bottom)
        }
    }

    private func barGradient(for ratio: Double) -> LinearGradient {
        if ratio >= 0.9 {
            return LinearGradient(colors: [Color.neonCyan, Color.neonCyan.opacity(0.6)], startPoint: .bottom, endPoint: .top)
        }
        if ratio >= 0.5 {
            return LinearGradient(colors: [Color.neonAmber, Color.neonAmber.opacity(0.6)], startPoint: .bottom, endPoint: .top)
        }
        return LinearGradient(colors: [Color.neonPink, Color.neonPink.opacity(0.6)], startPoint: .bottom, endPoint: .top)
    }
}

private struct InsightAverages {
    let mood: String
    let energy: String
    let sleep: String
}

#Preview {
    InsightsView()
}
