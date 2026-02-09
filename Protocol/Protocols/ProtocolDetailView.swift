import SwiftUI
import SwiftData

struct ProtocolDetailView: View {
    let protocolPlan: ProtocolPlan

    @State private var isEditing = false
    @State private var selectedVersion: ProtocolVersion?
    @State private var showVersionPicker = false

    var body: some View {
        let currentVersion = protocolPlan.currentVersion
        let displayVersion = selectedVersion ?? currentVersion

        ScrollView {
            LazyVStack(spacing: 16) {
                if let version = displayVersion {
                    let morning = items(for: .morning, in: version)
                    let day = items(for: .daytime, in: version)
                    let night = items(for: .night, in: version)

                    if !morning.isEmpty { slotSection(.morning, items: morning) }
                    if !day.isEmpty { slotSection(.daytime, items: day) }
                    if !night.isEmpty { slotSection(.night, items: night) }
                }

                versionsSection(currentVersion: currentVersion)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.voidBackground)
        .navigationTitle(protocolPlan.name)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(protocolPlan.name)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.white)
                    HStack(spacing: 8) {
                        if let version = displayVersion {
                            Text(version.label)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        Button(protocolPlan.isActive ? "Active" : "Inactive") {
                            protocolPlan.isActive.toggle()
                            protocolPlan.updatedAt = Date()
                        }
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(protocolPlan.isActive ? Color.neonCyan : Color.neonAmber)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { isEditing = true }
            }
        }
        .sheet(isPresented: $isEditing) {
            ProtocolEditorView(protocolPlan: protocolPlan)
        }
        .sheet(isPresented: $showVersionPicker) {
            ProtocolVersionPicker(
                versions: protocolPlan.sortedVersions,
                selectedVersion: $selectedVersion,
                currentVersion: currentVersion
            )
        }
        .onAppear {
            selectedVersion = currentVersion
        }
        .onChange(of: protocolPlan.updatedAt) { _, _ in
            selectedVersion = protocolPlan.currentVersion
        }
    }

    private func slotSection(_ slot: ProtocolSlot, items: [ProtocolItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon(for: slot))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.neonCyan.opacity(0.85))
                Text(slot.rawValue)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }

            ForEach(items) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.supplementName)
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.white)
                        Text("\(item.amount, specifier: "%.2f") \(item.unit.rawValue)")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .glassCard()
            }
        }
    }

    private func versionsSection(currentVersion: ProtocolVersion?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.neonCyan.opacity(0.85))
                Text("Versions")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Button {
                showVersionPicker = true
            } label: {
                HStack {
                    Text((selectedVersion ?? currentVersion)?.label ?? "Select")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .glassCard()
        }
    }

    private func items(for slot: ProtocolSlot, in version: ProtocolVersion) -> [ProtocolItem] {
        (version.items ?? []).filter { $0.slot == slot }
    }

    private func icon(for slot: ProtocolSlot) -> String {
        switch slot {
        case .morning: return "sun.max.fill"
        case .daytime: return "sun.haze.fill"
        case .night: return "moon.stars.fill"
        }
    }
}

private struct ProtocolVersionPicker: View {
    @Environment(\.dismiss) private var dismiss

    let versions: [ProtocolVersion]
    @Binding var selectedVersion: ProtocolVersion?
    let currentVersion: ProtocolVersion?

    var body: some View {
        NavigationStack {
            List {
                ForEach(versions) { version in
                    Button {
                        selectedVersion = version
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(version.label)
                                    .font(.system(.headline, design: .rounded))
                                Text(version.createdAt, style: .date)
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if version.id == (selectedVersion?.id ?? currentVersion?.id) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.neonCyan)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Versions")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                if selectedVersion == nil {
                    selectedVersion = currentVersion
                }
            }
        }
    }
}
