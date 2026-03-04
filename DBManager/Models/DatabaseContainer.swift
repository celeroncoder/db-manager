import Foundation

struct DatabaseContainer: Identifiable, Hashable {
    let id: String
    let name: String
    let engine: DatabaseEngine
    let state: ContainerState
    let image: String
    let hostPort: Int
    let containerPort: Int
    let createdAt: String
    let status: String

    var username: String
    var password: String
    var databaseName: String

    var connectionString: String {
        ConnectionStringBuilder.build(
            engine: engine,
            host: "localhost",
            port: hostPort,
            username: username,
            password: password,
            database: databaseName
        )
    }

    static func == (lhs: DatabaseContainer, rhs: DatabaseContainer) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct DockerPSContainer: Codable {
    let ID: String
    let Names: String
    let Image: String
    let Status: String
    let Ports: String
    let Labels: String
    let CreatedAt: String
    let State: String

    func toDatabaseContainer() -> DatabaseContainer? {
        let labels = parseLabels(Labels)
        guard let engineRaw = labels[Constants.engineLabelKey],
              let engine = DatabaseEngine(rawValue: engineRaw) else {
            return nil
        }

        let hostPort = parseHostPort(Ports) ?? engine.defaultPort

        return DatabaseContainer(
            id: ID,
            name: Names,
            engine: engine,
            state: ContainerState(from: Status),
            image: Image,
            hostPort: hostPort,
            containerPort: engine.defaultPort,
            createdAt: CreatedAt,
            status: Status,
            username: labels[Constants.userLabelKey] ?? Constants.defaultUsername,
            password: labels[Constants.passwordLabelKey] ?? "",
            databaseName: labels[Constants.databaseLabelKey] ?? Constants.defaultDatabaseName
        )
    }

    private func parseLabels(_ raw: String) -> [String: String] {
        var result: [String: String] = [:]
        for pair in raw.split(separator: ",") {
            let parts = pair.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                result[String(parts[0])] = String(parts[1])
            }
        }
        return result
    }

    private func parseHostPort(_ ports: String) -> Int? {
        // Format: "0.0.0.0:5432->5432/tcp" or ":::5432->5432/tcp"
        guard let arrow = ports.range(of: "->") else { return nil }
        let before = ports[ports.startIndex..<arrow.lowerBound]
        guard let colon = before.lastIndex(of: ":") else { return nil }
        let portStr = before[before.index(after: colon)...]
        return Int(portStr)
    }
}
