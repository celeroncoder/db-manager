import SwiftUI

struct ContainerLogsView: View {
    let containerId: String
    let isRunning: Bool

    @State private var logs = ""
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var autoScroll = true
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Toolbar
            HStack(spacing: 10) {
                Image(systemName: "text.alignleft")
                    .foregroundStyle(.secondary)

                TextField("Filter logs...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)
                    .accessibilityLabel("Filter log output")

                Spacer()

                Toggle(isOn: $autoScroll) {
                    Label("Auto-scroll", systemImage: "arrow.down.to.line")
                        .font(.caption)
                }
                .toggleStyle(.button)
                .controlSize(.small)

                Button {
                    Task { await loadLogs() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh logs")
                .disabled(isLoading)
                .accessibilityLabel("Refresh logs")
            }

            // Log content
            ZStack {
                if isLoading && logs.isEmpty {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Loading logs...")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else if let error, logs.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else if logs.isEmpty {
                    Text("No logs available")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    logScrollView
                }
            }
            .background(Color(.textBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        }
        .task(id: containerId) {
            await loadLogs()
        }
    }

    private var logScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    let lines = filteredLines
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1)")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .frame(width: 36, alignment: .trailing)

                            Text(line)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.primary)
                                .textSelection(.enabled)
                        }
                        .id(index)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 1)
                    }
                }
                .onChange(of: logs) {
                    if autoScroll {
                        let count = filteredLines.count
                        if count > 0 {
                            withAnimation(.easeOut(duration: 0.15)) {
                                proxy.scrollTo(count - 1, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .frame(minHeight: 300)
    }

    private var filteredLines: [String] {
        let allLines = logs.components(separatedBy: "\n").filter { !$0.isEmpty }
        if searchText.isEmpty {
            return allLines
        }
        return allLines.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    private func loadLogs() async {
        isLoading = true
        error = nil
        do {
            logs = try await DockerService.shared.containerLogs(id: containerId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
