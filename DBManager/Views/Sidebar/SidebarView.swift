import SwiftUI

struct SidebarView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var listVM = ContainerListViewModel()
    @State private var sidebarFilter: ContainerFilter = .all

    private var sidebarContainers: [DatabaseContainer] {
        listVM.filtered(appVM.filtered(by: sidebarFilter))
    }

    var body: some View {
        @Bindable var appVM = appVM

        VStack(spacing: 0) {
            // Docker status
            dockerStatusHeader

            // Filter bar — local to sidebar
            SidebarFilterBar(
                selected: $sidebarFilter,
                totalCount: appVM.containers.count,
                runningCount: appVM.runningCount,
                stoppedCount: appVM.stoppedCount
            )

            Divider()
                .padding(.horizontal, 12)
                .padding(.top, 4)

            // Searchable container list
            List(selection: $appVM.selectedContainer) {
                if sidebarContainers.isEmpty {
                    ContentUnavailableView {
                        Label("No Databases", systemImage: "cylinder")
                    } description: {
                        Text("No databases match your filter.")
                    }
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(sidebarContainers) { container in
                        SidebarRow(container: container)
                            .tag(container)
                    }
                }
            }
            .listStyle(.sidebar)
            .searchable(text: $listVM.searchText, placement: .sidebar, prompt: "Search databases...")

            Divider()

            // New database button
            newDatabaseButton
        }
    }

    // MARK: - Docker Status

    private var dockerStatusHeader: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(appVM.isDockerRunning ? .green : .red)
                .frame(width: 8, height: 8)
                .shadow(color: appVM.isDockerRunning ? .green.opacity(0.5) : .red.opacity(0.5), radius: 4)

            Text(appVM.isDockerRunning ? "Docker Running" : "Docker Not Running")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            if appVM.isLoading {
                ProgressView()
                    .controlSize(.mini)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - New Database Button

    private var newDatabaseButton: some View {
        Button {
            appVM.showCreateSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)

                Text("New Database")
                    .font(.callout)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Create new database")
    }
}

// MARK: - Sidebar Filter Bar (horizontal grouped pills)

struct SidebarFilterBar: View {
    @Binding var selected: ContainerFilter
    let totalCount: Int
    let runningCount: Int
    let stoppedCount: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(ContainerFilter.allCases) { filter in
                let count = count(for: filter)
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selected = filter
                    }
                } label: {
                    HStack(spacing: 5) {
                        if filter == .running {
                            Circle()
                                .fill(.green)
                                .frame(width: 6, height: 6)
                        } else if filter == .stopped {
                            Circle()
                                .stroke(Color.secondary, lineWidth: 1.5)
                                .frame(width: 6, height: 6)
                        }

                        Text(filter.rawValue)
                            .font(.caption)
                            .fontWeight(selected == filter ? .semibold : .regular)

                        Text("\(count)")
                            .font(.system(.caption2, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundStyle(selected == filter ? .primary : .secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(selected == filter ? Color.primary.opacity(0.1) : .clear, in: RoundedRectangle(cornerRadius: 6))
                    .contentShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(filter.rawValue) filter, \(count) items")
                .accessibilityAddTraits(selected == filter ? .isSelected : [])
            }
        }
        .padding(3)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    private func count(for filter: ContainerFilter) -> Int {
        switch filter {
        case .all: totalCount
        case .running: runningCount
        case .stopped: stoppedCount
        }
    }
}

// MARK: - Sidebar Row

struct SidebarRow: View {
    let container: DatabaseContainer

    var body: some View {
        HStack(spacing: 10) {
            EngineIcon(engine: container.engine, size: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(container.name)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(container.engine.displayName)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text(":\(container.hostPort)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }

            Spacer()

            StatusBadge(state: container.state, compact: true)
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .accessibilityLabel("\(container.name), \(container.engine.displayName), \(container.state.displayName)")
    }
}
