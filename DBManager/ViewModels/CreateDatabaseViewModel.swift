import SwiftUI

@Observable
final class CreateDatabaseViewModel {
    var config: DatabaseConfig
    var isCreating = false
    var isPulling = false
    var pullOutput = ""
    var error: String?
    var createdContainerId: String?
    var showPassword = false

    private let docker = DockerService.shared

    init(engine: DatabaseEngine = .postgres) {
        self.config = DatabaseConfig(engine: engine)
    }

    var selectedEngine: DatabaseEngine {
        get { config.engine }
        set {
            config = DatabaseConfig(engine: newValue)
        }
    }

    var isValid: Bool {
        !config.containerName.isEmpty &&
        config.hostPort > 0 &&
        config.hostPort <= 65535 &&
        !config.password.isEmpty &&
        (config.engine.supportsDatabase ? !config.databaseName.isEmpty : true)
    }

    var containerNameError: String? {
        if config.containerName.isEmpty { return "Name is required" }
        let valid = config.containerName.range(
            of: "^[a-zA-Z0-9][a-zA-Z0-9_.-]+$",
            options: .regularExpression
        )
        if valid == nil { return "Invalid Docker name (alphanumeric, dots, dashes, underscores)" }
        return nil
    }

    var portError: String? {
        if config.hostPort <= 0 || config.hostPort > 65535 {
            return "Port must be 1-65535"
        }
        return nil
    }

    func regeneratePassword() {
        config.password = DatabaseConfig.generatePassword()
    }

    func regenerateName() {
        config.containerName = "\(config.engine.defaultContainerPrefix)-dev-\(Int.random(in: 100...999))"
    }

    func create() async -> Bool {
        guard isValid else { return false }

        isCreating = true
        error = nil
        pullOutput = ""

        defer { isCreating = false }

        do {
            // Check and pull image
            let imageReady = await docker.imageExists(config.engine.dockerImage)
            if !imageReady {
                isPulling = true
                for await line in docker.pullImage(config.engine.dockerImage) {
                    pullOutput = line
                }
                isPulling = false
            }

            // Create container
            let containerId = try await docker.createAndStart(config: config)
            createdContainerId = containerId
            return true
        } catch {
            self.error = error.localizedDescription
            isPulling = false
            return false
        }
    }
}
