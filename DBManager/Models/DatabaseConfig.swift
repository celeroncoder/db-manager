import Foundation

struct DatabaseConfig {
    var engine: DatabaseEngine
    var containerName: String
    var hostPort: Int
    var databaseName: String
    var username: String
    var password: String

    init(engine: DatabaseEngine) {
        self.engine = engine
        self.containerName = "\(engine.defaultContainerPrefix)-dev-\(Int.random(in: 100...999))"
        self.hostPort = engine.defaultPort
        self.databaseName = Constants.defaultDatabaseName
        self.username = Constants.defaultUsername
        self.password = Self.generatePassword()
    }

    static func generatePassword(length: Int = Constants.defaultPasswordLength) -> String {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in chars.randomElement()! })
    }

    var dockerRunArguments: [String] {
        var args = [
            "docker", "run", "-d",
            "--name", containerName,
            "-p", "\(hostPort):\(engine.defaultPort)",
            "--label", Constants.appLabel,
            "--label", "\(Constants.engineLabelKey)=\(engine.rawValue)",
            "--label", "\(Constants.portLabelKey)=\(hostPort)",
            "--label", "\(Constants.userLabelKey)=\(username)",
            "--label", "\(Constants.passwordLabelKey)=\(password)",
            "--label", "\(Constants.databaseLabelKey)=\(databaseName)",
        ]

        let env = engine.environmentVars

        switch engine {
        case .postgres:
            args += ["-e", "\(env.userKey)=\(username)"]
            args += ["-e", "\(env.passwordKey)=\(password)"]
            args += ["-e", "\(env.dbKey!)=\(databaseName)"]

        case .mysql:
            args += ["-e", "\(env.passwordKey)=\(password)"]
            args += ["-e", "\(env.dbKey!)=\(databaseName)"]
            args += ["-e", "MYSQL_USER=\(username)"]
            args += ["-e", "MYSQL_PASSWORD=\(password)"]

        case .mariadb:
            args += ["-e", "\(env.passwordKey)=\(password)"]
            args += ["-e", "\(env.dbKey!)=\(databaseName)"]
            args += ["-e", "MARIADB_USER=\(username)"]
            args += ["-e", "MARIADB_PASSWORD=\(password)"]

        case .mongo:
            args += ["-e", "\(env.userKey)=\(username)"]
            args += ["-e", "\(env.passwordKey)=\(password)"]
            if let dbKey = env.dbKey {
                args += ["-e", "\(dbKey)=\(databaseName)"]
            }

        case .redis:
            if !password.isEmpty {
                args += ["--requirepass", password]
            }
        }

        args.append(engine.dockerImage)

        if engine == .redis && !password.isEmpty {
            args += ["redis-server", "--requirepass", password]
        }

        return args
    }

    var dockerRunCommand: String {
        var parts = [
            "docker run -d",
            "--name \(containerName)",
            "-p \(hostPort):\(engine.defaultPort)",
            "--label \(Constants.appLabel)",
            "--label \(Constants.engineLabelKey)=\(engine.rawValue)",
            "--label \(Constants.portLabelKey)=\(hostPort)",
            "--label \(Constants.userLabelKey)=\(username)",
            "--label \(Constants.passwordLabelKey)=\(password)",
            "--label \(Constants.databaseLabelKey)=\(databaseName)",
        ]

        let env = engine.environmentVars

        switch engine {
        case .postgres:
            parts += [
                "-e \(env.userKey)=\(username)",
                "-e \(env.passwordKey)=\(password)",
                "-e \(env.dbKey!)=\(databaseName)",
            ]

        case .mysql:
            parts += [
                "-e \(env.passwordKey)=\(password)",
                "-e \(env.dbKey!)=\(databaseName)",
                "-e MYSQL_USER=\(username)",
                "-e MYSQL_PASSWORD=\(password)",
            ]

        case .mariadb:
            parts += [
                "-e \(env.passwordKey)=\(password)",
                "-e \(env.dbKey!)=\(databaseName)",
                "-e MARIADB_USER=\(username)",
                "-e MARIADB_PASSWORD=\(password)",
            ]

        case .mongo:
            parts += [
                "-e \(env.userKey)=\(username)",
                "-e \(env.passwordKey)=\(password)",
            ]
            if let dbKey = env.dbKey {
                parts += ["-e \(dbKey)=\(databaseName)"]
            }

        case .redis:
            break
        }

        parts.append(engine.dockerImage)

        if engine == .redis && !password.isEmpty {
            parts += ["redis-server", "--requirepass \(password)"]
        }

        return parts.joined(separator: " ")
    }
}
