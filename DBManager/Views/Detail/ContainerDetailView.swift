import SwiftUI

struct ContainerDetailView: View {
    let container: DatabaseContainer
    @Environment(AppViewModel.self) private var appVM
    @State private var selectedTab = 0
    @State private var stats: ContainerStats?
    @State private var showDeleteConfirm = false
    @State private var isPerformingAction = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Back + Header
                detailHeader

                // Connection info
                ConnectionInfoView(container: container)

                // Stats (if running)
                if container.state == .running {
                    statsSection
                }

                // Tabs: Overview / Logs / Environment
                tabSection
            }
            .padding(24)
        }
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appVM.selectedContainer = nil
                    }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .help("Back to Dashboard")
                .keyboardShortcut(.escape, modifiers: [])
            }

            ToolbarItemGroup(placement: .primaryAction) {
                if container.state.isActive {
                    Button {
                        performAction { await appVM.stopContainer(container) }
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .tint(.orange)
                    .help("Stop container")
                    .disabled(isPerformingAction)

                    Button {
                        performAction { await appVM.restartContainer(container) }
                    } label: {
                        Label("Restart", systemImage: "arrow.clockwise")
                    }
                    .help("Restart container")
                    .disabled(isPerformingAction)
                } else {
                    Button {
                        performAction { await appVM.startContainer(container) }
                    } label: {
                        Label("Start", systemImage: "play.fill")
                    }
                    .tint(.green)
                    .help("Start container")
                    .disabled(isPerformingAction)
                }

                Button {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .tint(.red)
                .help("Delete container")
                .disabled(isPerformingAction)
            }
        }
        .navigationTitle(container.name)
        .navigationSubtitle(container.engine.displayName)
        .task(id: container.id) {
            await loadStats()
        }
        .confirmationDialog("Delete Container", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task {
                    await appVM.removeContainer(container)
                }
            }
        } message: {
            Text("Are you sure you want to delete \"\(container.name)\"? This action cannot be undone.")
        }
    }

    // MARK: - Header

    private var detailHeader: some View {
        HStack(spacing: 16) {
            EngineIconLarge(engine: container.engine, size: 56)

            VStack(alignment: .leading, spacing: 6) {
                Text(container.name)
                    .font(.title)
                    .fontWeight(.bold)

                HStack(spacing: 12) {
                    StatusBadge(state: container.state)

                    Text(container.status)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(container.image)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.quaternary, in: Capsule())
                }
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(container.name), \(container.engine.displayName), \(container.state.displayName)")
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 12) {
            MetricGauge(
                title: "CPU",
                value: stats?.CPUPerc ?? "--",
                systemImage: "cpu"
            )
            MetricGauge(
                title: "Memory",
                value: stats?.MemUsage.components(separatedBy: " / ").first ?? "--",
                systemImage: "memorychip"
            )
            MetricGauge(
                title: "Network I/O",
                value: stats?.NetIO ?? "--",
                systemImage: "network"
            )
            MetricGauge(
                title: "Block I/O",
                value: stats?.BlockIO ?? "--",
                systemImage: "internaldrive"
            )
        }
    }

    // MARK: - Tabs

    private var tabSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("", selection: $selectedTab) {
                Text("Overview").tag(0)
                Text("Logs").tag(1)
                Text("Environment").tag(2)
            }
            .pickerStyle(.segmented)
            .frame(width: 300)

            switch selectedTab {
            case 0: overviewTab
            case 1: ContainerLogsView(containerId: container.id, isRunning: container.state == .running)
            case 2: environmentTab
            default: EmptyView()
            }
        }
    }

    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            DetailRow(label: "Container ID", value: String(container.id.prefix(12)))
            Divider().padding(.vertical, 4)
            DetailRow(label: "Image", value: container.image)
            Divider().padding(.vertical, 4)
            DetailRow(label: "Status", value: container.status)
            Divider().padding(.vertical, 4)
            DetailRow(label: "Created", value: container.createdAt)
            Divider().padding(.vertical, 4)
            DetailRow(label: "Port Mapping", value: "\(container.hostPort) -> \(container.containerPort)")
        }
        .padding(16)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
    }

    private var environmentTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            let env = container.engine.environmentVars
            DetailRow(label: env.userKey, value: container.username)
            Divider().padding(.vertical, 4)
            DetailRow(label: env.passwordKey, value: "********")
            if let dbKey = env.dbKey {
                Divider().padding(.vertical, 4)
                DetailRow(label: dbKey, value: container.databaseName)
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private func performAction(_ action: @escaping () async -> Void) {
        isPerformingAction = true
        Task {
            await action()
            isPerformingAction = false
        }
    }

    private func loadStats() async {
        guard container.state == .running else {
            stats = nil
            return
        }
        do {
            stats = try await DockerService.shared.containerStats(id: container.id)
        } catch {
            stats = nil
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 140, alignment: .leading)

            Text(value)
                .font(.system(.callout, design: .monospaced))
                .textSelection(.enabled)

            Spacer()

            CopyButton(text: value)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
