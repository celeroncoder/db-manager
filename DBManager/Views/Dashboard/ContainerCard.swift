import SwiftUI

struct ContainerCard: View {
    let container: DatabaseContainer
    let onSelect: () -> Void

    @Environment(AppViewModel.self) private var appVM
    @State private var isHovered = false
    @State private var showDeleteConfirm = false
    @State private var isPerformingAction = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Top row: icon + name + status — tappable to open detail
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    EngineIconLarge(engine: container.engine, size: 44)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(container.name)
                            .font(.headline)
                            .lineLimit(1)
                            .foregroundStyle(.primary)

                        Text(container.engine.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    StatusBadge(state: container.state)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider()

            // Connection info
            HStack(spacing: 16) {
                InfoItem(icon: "network", label: "Host", value: "localhost")
                InfoItem(icon: "number", label: "Port", value: "\(container.hostPort)")
                if container.engine.supportsDatabase {
                    InfoItem(icon: "cylinder", label: "DB", value: container.databaseName)
                }
            }

            // Connection string
            HStack(spacing: 8) {
                Text(container.connectionString)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)

                Spacer()

                CopyButton(text: container.connectionString, label: "Copy")
            }
            .padding(8)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))

            // Actions
            HStack(spacing: 8) {
                if container.state.isActive {
                    Button {
                        performAction { await appVM.stopContainer(container) }
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .disabled(isPerformingAction)
                    .accessibilityLabel("Stop \(container.name)")
                } else {
                    Button {
                        performAction { await appVM.startContainer(container) }
                    } label: {
                        Label("Start", systemImage: "play.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                    .disabled(isPerformingAction)
                    .accessibilityLabel("Start \(container.name)")
                }

                Spacer()

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .tint(.red)
                .help("Delete container")
                .accessibilityLabel("Delete \(container.name)")
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.background)
                .shadow(color: .black.opacity(isHovered ? 0.12 : 0.06), radius: isHovered ? 12 : 6, y: isHovered ? 4 : 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(container.engine.accentColor.opacity(isHovered ? 0.3 : 0.1), lineWidth: 1)
        }
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .confirmationDialog("Delete Container", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task { await appVM.removeContainer(container) }
            }
        } message: {
            Text("Are you sure you want to delete \"\(container.name)\"? This action cannot be undone.")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(container.name), \(container.engine.displayName), \(container.state.displayName)")
    }

    private func performAction(_ action: @escaping () async -> Void) {
        isPerformingAction = true
        Task {
            await action()
            isPerformingAction = false
        }
    }
}

struct InfoItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
