import SwiftUI

struct ConnectionInfoView: View {
    let container: DatabaseContainer
    @State private var showPassword = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connection")
                .font(.headline)

            // Connection URI
            HStack(spacing: 12) {
                Image(systemName: "link")
                    .font(.title3)
                    .foregroundStyle(container.engine.accentColor)
                    .frame(width: 32)

                Text(container.connectionString)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .lineLimit(2)

                Spacer()

                CopyButton(text: container.connectionString, label: "Copy")
            }
            .padding(14)
            .background(container.engine.accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(container.engine.accentColor.opacity(0.15), lineWidth: 1)
            }

            // Individual fields
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ConnectionField(label: "Host", value: "localhost", icon: "server.rack")
                ConnectionField(label: "Port", value: "\(container.hostPort)", icon: "number")
                ConnectionField(label: "Username", value: container.username, icon: "person")
                ConnectionField(
                    label: "Password",
                    value: showPassword ? container.password : String(repeating: "*", count: 8),
                    icon: "lock",
                    actualValue: container.password,
                    showToggle: true,
                    isRevealed: $showPassword
                )
                if container.engine.supportsDatabase {
                    ConnectionField(label: "Database", value: container.databaseName, icon: "cylinder")
                }
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

struct ConnectionField: View {
    let label: String
    let value: String
    let icon: String
    var actualValue: String? = nil
    var showToggle: Bool = false
    @Binding var isRevealed: Bool

    init(label: String, value: String, icon: String, actualValue: String? = nil, showToggle: Bool = false, isRevealed: Binding<Bool> = .constant(false)) {
        self.label = label
        self.value = value
        self.icon = icon
        self.actualValue = actualValue
        self.showToggle = showToggle
        self._isRevealed = isRevealed
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Text(value)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
            }

            Spacer()

            if showToggle {
                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            CopyButton(text: actualValue ?? value)
        }
        .padding(10)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
    }
}
