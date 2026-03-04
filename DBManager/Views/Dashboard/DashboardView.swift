import SwiftUI

struct DashboardView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var dashboardFilter: ContainerFilter = .all

    private let columns = [GridItem(.adaptive(minimum: 300), spacing: 16)]

    private var displayedContainers: [DatabaseContainer] {
        appVM.filtered(by: dashboardFilter)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                header

                if !appVM.isDockerRunning {
                    dockerNotRunningView
                } else if appVM.containers.isEmpty && !appVM.isLoading {
                    emptyStateView
                } else {
                    // Clickable stat pills — act as dashboard filter
                    filterStatsBar

                    // Container grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(displayedContainers) { container in
                            ContainerCard(container: container) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    appVM.selectedContainer = container
                                }
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: displayedContainers.map(\.id))

                    if displayedContainers.isEmpty {
                        Text("No \(dashboardFilter.rawValue.lowercased()) databases.")
                            .font(.callout)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    }
                }
            }
            .padding(24)
        }
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .navigationTitle("DB Manager")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    appVM.showCreateSheet = true
                } label: {
                    Label("New Database", systemImage: "plus")
                }
                .help("Create a new database (Cmd+N)")
                .accessibilityLabel("Create new database")
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await appVM.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .help("Refresh containers (Cmd+R)")
                .disabled(appVM.isLoading)
                .accessibilityLabel("Refresh container list")
            }
        }
        .overlay {
            if appVM.isLoading && appVM.containers.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Loading containers...")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("My Databases")
                    .font(.title)
                    .fontWeight(.bold)

                Text("\(appVM.containers.count) database\(appVM.containers.count == 1 ? "" : "s") managed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Filter Stats Bar

    private var filterStatsBar: some View {
        HStack(spacing: 8) {
            FilterStatPill(
                label: "Total",
                value: "\(appVM.containers.count)",
                color: .primary,
                isSelected: dashboardFilter == .all
            ) {
                withAnimation(.easeInOut(duration: 0.15)) { dashboardFilter = .all }
            }

            FilterStatPill(
                label: "Running",
                value: "\(appVM.runningCount)",
                color: .green,
                isSelected: dashboardFilter == .running
            ) {
                withAnimation(.easeInOut(duration: 0.15)) { dashboardFilter = .running }
            }

            FilterStatPill(
                label: "Stopped",
                value: "\(appVM.stoppedCount)",
                color: .secondary,
                isSelected: dashboardFilter == .stopped
            ) {
                withAnimation(.easeInOut(duration: 0.15)) { dashboardFilter = .stopped }
            }
        }
    }

    // MARK: - Empty States

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cylinder.split.1x2")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("No Databases Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create your first database instance to get started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                appVM.showCreateSheet = true
            } label: {
                Label("Create Database", systemImage: "plus")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    private var dockerNotRunningView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Docker Not Running")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Start Docker Desktop, OrbStack, or Colima to manage databases.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            Button {
                Task { await appVM.checkDocker() }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
}

// MARK: - Filter Stat Pill (clickable)

struct FilterStatPill: View {
    let label: String
    let value: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(value)
                    .font(.system(.callout, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(color)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected ? color.opacity(0.12) : (isHovered ? color.opacity(0.06) : Color.clear),
                in: Capsule()
            )
            .background(.quaternary.opacity(isSelected ? 0 : 0.5), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(isSelected ? color.opacity(0.3) : .clear, lineWidth: 1)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityLabel("\(value) \(label)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
