import SwiftUI
import SwiftData

struct ProtocolsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProtocolPlan.updatedAt, order: .reverse) private var protocols: [ProtocolPlan]
    @State private var isCreating = false
    @State private var pendingDelete: ProtocolPlan?
    @State private var editTarget: ProtocolPlan?
    @State private var openTargetID: UUID?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.voidBackground.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        if protocols.isEmpty {
                            emptyState
                        } else {
                            if !activeProtocols.isEmpty {
                                sectionHeader("Active", systemImage: "bolt.circle.fill")
                                ForEach(activeProtocols) { plan in
                                    protocolRow(plan)
                                }
                            }

                            if !inactiveProtocols.isEmpty {
                                sectionHeader("Inactive", systemImage: "pause.circle.fill")
                                ForEach(inactiveProtocols) { plan in
                                    protocolRow(plan)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Protocols")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isCreating) {
                ProtocolEditorView(protocolPlan: nil)
            }
            .sheet(item: $editTarget) { plan in
                ProtocolEditorView(protocolPlan: plan)
            }
            .alert("Delete Protocol?", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })) {
                Button("Delete", role: .destructive) {
                    if let plan = pendingDelete {
                        modelContext.delete(plan)
                    }
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: {
                Text("This will remove the protocol and all versions.")
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isCreating = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .accessibilityLabel("Create Protocol")
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "capsule")
                .font(.system(size: 42, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.neonCyan)

            Text("No protocols yet")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(.white)

            Text("Create your first supplement protocol to track daily routines.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .glassCard()
    }

    private var activeProtocols: [ProtocolPlan] {
        protocols.filter { $0.isActive }
    }

    private var inactiveProtocols: [ProtocolPlan] {
        protocols.filter { !$0.isActive }
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.neonCyan.opacity(0.85))
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func protocolRow(_ plan: ProtocolPlan) -> some View {
        ZStack {
            NavigationLink(isActive: Binding(get: { openTargetID == plan.id }, set: { if !$0 { openTargetID = nil } })) {
                ProtocolDetailView(protocolPlan: plan)
            } label: {
                EmptyView()
            }
            .opacity(0)

            NavigationLink {
                ProtocolDetailView(protocolPlan: plan)
            } label: {
                ProtocolCard(plan: plan)
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button {
                    editTarget = plan
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button {
                    plan.isActive.toggle()
                    plan.updatedAt = Date()
                } label: {
                    Label(plan.isActive ? "Deactivate" : "Activate", systemImage: plan.isActive ? "pause.circle" : "play.circle")
                }
                Button(role: .destructive) {
                    pendingDelete = plan
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

private struct ProtocolCard: View {
    let plan: ProtocolPlan

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(plan.name)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)

                Text("Updated \(plan.updatedAt, style: .date)")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            if let current = plan.currentVersion {
                Text(current.label)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .glassCard()
    }
}

#Preview {
    ProtocolsView()
}
