import SwiftUI

struct CreateDatabaseSheet: View {
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CreateDatabaseViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            sheetHeader

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Engine picker
                    engineSection

                    Divider()

                    // Configuration form
                    configSection

                    // Error display
                    if let error = viewModel.error {
                        errorBanner(error)
                    }

                    // Pull progress
                    if viewModel.isPulling {
                        pullProgressView
                    }
                }
                .padding(24)
            }

            Divider()

            // Footer with actions
            sheetFooter
        }
        .frame(width: 560, height: 620)
    }

    // MARK: - Header

    private var sheetHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Create Database")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Set up a new database instance powered by Docker")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
    }

    // MARK: - Engine

    private var engineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Database Engine")
                .font(.headline)

            EnginePickerView(selected: Bindable(viewModel).selectedEngine)
        }
    }

    // MARK: - Config

    private var configSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configuration")
                .font(.headline)

            // Container name
            VStack(alignment: .leading, spacing: 4) {
                Text("Container Name")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    TextField("Container name", text: Bindable(viewModel).config.containerName)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        viewModel.regenerateName()
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    .help("Generate random name")
                }

                if let error = viewModel.containerNameError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            // Port
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Host Port")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField("Port", value: Bindable(viewModel).config.hostPort, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)

                    if let error = viewModel.portError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                if viewModel.config.engine.supportsDatabase {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Database Name")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("Database", text: Bindable(viewModel).config.databaseName)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }

            // Credentials
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Username")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField("Username", text: Bindable(viewModel).config.username)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Password")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        if viewModel.showPassword {
                            TextField("Password", text: Bindable(viewModel).config.password)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField("Password", text: Bindable(viewModel).config.password)
                                .textFieldStyle(.roundedBorder)
                        }

                        Button {
                            viewModel.showPassword.toggle()
                        } label: {
                            Image(systemName: viewModel.showPassword ? "eye.slash" : "eye")
                        }
                        .help(viewModel.showPassword ? "Hide password" : "Show password")

                        Button {
                            viewModel.regeneratePassword()
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        .help("Generate new password")
                    }
                }
            }
        }
    }

    // MARK: - Progress

    private var pullProgressView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ProgressView()
                    .controlSize(.small)
                Text("Pulling \(viewModel.config.engine.dockerImage)...")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if !viewModel.pullOutput.isEmpty {
                Text(viewModel.pullOutput)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(3)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Error

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)

            Text(message)
                .font(.callout)

            Spacer()
        }
        .padding(12)
        .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Footer

    private var sheetFooter: some View {
        HStack {
            // Preview connection string
            if viewModel.isValid {
                Text(ConnectionStringBuilder.build(
                    engine: viewModel.config.engine,
                    host: "localhost",
                    port: viewModel.config.hostPort,
                    username: viewModel.config.username,
                    password: "****",
                    database: viewModel.config.databaseName
                ))
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
            }

            Spacer()

            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            Button {
                Task {
                    let success = await viewModel.create()
                    if success {
                        await appVM.refresh()
                        dismiss()
                    }
                }
            } label: {
                if viewModel.isCreating {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.horizontal, 8)
                } else {
                    Text("Create Database")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isValid || viewModel.isCreating)
            .keyboardShortcut(.defaultAction)
        }
        .padding(20)
    }
}
