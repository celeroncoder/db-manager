import Foundation

actor DockerService {
    static let shared = DockerService()

    private let decoder = JSONDecoder()

    // MARK: - Health Check

    func isDockerRunning() async -> Bool {
        do {
            _ = try await Shell.execute("docker info --format '{{.ID}}'")
            return true
        } catch {
            return false
        }
    }

    // MARK: - Image Operations

    func imageExists(_ image: String) async -> Bool {
        do {
            _ = try await Shell.execute("docker image inspect \(image) --format '{{.ID}}'")
            return true
        } catch {
            return false
        }
    }

    nonisolated func pullImage(_ image: String) -> AsyncStream<String> {
        Shell.stream("docker pull \(image)")
    }

    // MARK: - Container Listing

    func listContainers() async throws -> [DatabaseContainer] {
        let format = "{{json .}}"
        let output = try await Shell.execute(
            "docker ps -a --filter label=\(Constants.appLabel) --format '\(format)'"
        )

        guard !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        var containers: [DatabaseContainer] = []

        for line in output.components(separatedBy: "\n") where !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            guard let data = line.data(using: .utf8) else { continue }
            do {
                let raw = try decoder.decode(DockerPSContainer.self, from: data)
                if let container = raw.toDatabaseContainer() {
                    containers.append(container)
                }
            } catch {
                continue
            }
        }

        return containers
    }

    // MARK: - Container Lifecycle

    func createAndStart(config: DatabaseConfig) async throws -> String {
        // Check if image exists, pull if needed
        if !(await imageExists(config.engine.dockerImage)) {
            // Pull synchronously (caller can use pullImage for streaming)
            _ = try await Shell.execute("docker pull \(config.engine.dockerImage)")
        }

        let output = try await Shell.execute(config.dockerRunCommand)
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func startContainer(id: String) async throws {
        _ = try await Shell.execute("docker start \(id)")
    }

    func stopContainer(id: String) async throws {
        _ = try await Shell.execute("docker stop \(id)")
    }

    func restartContainer(id: String) async throws {
        _ = try await Shell.execute("docker restart \(id)")
    }

    func removeContainer(id: String, force: Bool = false) async throws {
        let forceFlag = force ? " -f" : ""
        _ = try await Shell.execute("docker rm\(forceFlag) \(id)")
    }

    // MARK: - Container Info

    func containerLogs(id: String, tail: Int = Constants.logTailCount) async throws -> String {
        try await Shell.execute("docker logs --tail \(tail) \(id) 2>&1")
    }

    nonisolated func containerLogStream(id: String, tail: Int = 50) -> AsyncStream<String> {
        Shell.stream("docker logs --tail \(tail) --follow \(id) 2>&1")
    }

    func containerStats(id: String) async throws -> ContainerStats {
        let output = try await Shell.execute(
            "docker stats --no-stream --format '{{json .}}' \(id)"
        )
        guard let data = output.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8) else {
            throw ShellError.failed("Failed to parse stats", code: 1)
        }
        return try decoder.decode(ContainerStats.self, from: data)
    }
}

struct ContainerStats: Codable {
    let Container: String
    let CPUPerc: String
    let MemUsage: String
    let MemPerc: String
    let NetIO: String
    let BlockIO: String

    var cpuPercent: Double {
        Double(CPUPerc.replacingOccurrences(of: "%", with: "")) ?? 0
    }

    var memoryPercent: Double {
        Double(MemPerc.replacingOccurrences(of: "%", with: "")) ?? 0
    }
}
