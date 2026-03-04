import Foundation

enum ConnectionStringBuilder {
    static func build(
        engine: DatabaseEngine,
        host: String = "localhost",
        port: Int,
        username: String,
        password: String,
        database: String
    ) -> String {
        switch engine {
        case .postgres:
            return "postgresql://\(username):\(password)@\(host):\(port)/\(database)"
        case .mysql:
            return "mysql://\(username):\(password)@\(host):\(port)/\(database)"
        case .mariadb:
            return "mariadb://\(username):\(password)@\(host):\(port)/\(database)"
        case .mongo:
            return "mongodb://\(username):\(password)@\(host):\(port)/\(database)?authSource=admin"
        case .redis:
            if password.isEmpty {
                return "redis://\(host):\(port)"
            }
            return "redis://:\(password)@\(host):\(port)"
        }
    }
}
