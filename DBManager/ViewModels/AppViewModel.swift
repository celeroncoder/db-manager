import SwiftUI

@Observable
final class AppViewModel {
    var containers: [DatabaseContainer] = []
    var selectedContainer: DatabaseContainer?
    var isDockerRunning = false
    var isLoading = false
    var showCreateSheet = false
    var errorMessage: String?

    var runningCount: Int {
        containers.filter { $0.state == .running }.count
    }

    var stoppedCount: Int {
        containers.filter { !$0.state.isActive }.count
    }

    func filtered(by filter: ContainerFilter) -> [DatabaseContainer] {
        switch filter {
        case .all: containers
        case .running: containers.filter { $0.state == .running }
        case .stopped: containers.filter { !$0.state.isActive }
        }
    }

    private let docker = DockerService.shared

    func checkDocker() async {
        isDockerRunning = await docker.isDockerRunning()
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        await checkDocker()

        guard isDockerRunning else { return }

        do {
            containers = try await docker.listContainers()
            // Update selected container if it still exists
            if let selected = selectedContainer {
                selectedContainer = containers.first { $0.id == selected.id }
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startContainer(_ container: DatabaseContainer) async {
        do {
            try await docker.startContainer(id: container.id)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopContainer(_ container: DatabaseContainer) async {
        do {
            try await docker.stopContainer(id: container.id)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restartContainer(_ container: DatabaseContainer) async {
        do {
            try await docker.restartContainer(id: container.id)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeContainer(_ container: DatabaseContainer) async {
        do {
            try await docker.removeContainer(id: container.id, force: true)
            if selectedContainer?.id == container.id {
                selectedContainer = nil
            }
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startPolling() async {
        while !Task.isCancelled {
            await refresh()
            try? await Task.sleep(for: .seconds(Constants.refreshInterval))
        }
    }
}
