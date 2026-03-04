import SwiftUI

enum DatabaseEngine: String, CaseIterable, Codable, Identifiable {
    case postgres
    case mysql
    case mariadb
    case mongo
    case redis

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .postgres: "PostgreSQL"
        case .mysql: "MySQL"
        case .mariadb: "MariaDB"
        case .mongo: "MongoDB"
        case .redis: "Redis"
        }
    }

    var dockerImage: String {
        switch self {
        case .postgres: "postgres:16-alpine"
        case .mysql: "mysql:8.0"
        case .mariadb: "mariadb:11"
        case .mongo: "mongo:7"
        case .redis: "redis:7-alpine"
        }
    }

    var defaultPort: Int {
        switch self {
        case .postgres: 5432
        case .mysql: 3306
        case .mariadb: 3306
        case .mongo: 27017
        case .redis: 6379
        }
    }

    var iconName: String {
        switch self {
        case .postgres: "cylinder.split.1x2"
        case .mysql: "cylinder"
        case .mariadb: "cylinder.fill"
        case .mongo: "leaf"
        case .redis: "bolt.horizontal"
        }
    }

    var accentColor: Color {
        switch self {
        case .postgres: Color(red: 0.20, green: 0.40, blue: 0.57) // #336791
        case .mysql: Color(red: 0.27, green: 0.47, blue: 0.63)    // #4479A1
        case .mariadb: Color(red: 0.0, green: 0.21, blue: 0.27)   // #003545
        case .mongo: Color(red: 0.28, green: 0.63, blue: 0.28)    // #47A248
        case .redis: Color(red: 0.86, green: 0.22, blue: 0.18)    // #DC382D
        }
    }

    var environmentVars: (userKey: String, passwordKey: String, dbKey: String?) {
        switch self {
        case .postgres:
            return ("POSTGRES_USER", "POSTGRES_PASSWORD", "POSTGRES_DB")
        case .mysql:
            return ("MYSQL_USER", "MYSQL_ROOT_PASSWORD", "MYSQL_DATABASE")
        case .mariadb:
            return ("MARIADB_USER", "MARIADB_ROOT_PASSWORD", "MARIADB_DATABASE")
        case .mongo:
            return ("MONGO_INITDB_ROOT_USERNAME", "MONGO_INITDB_ROOT_PASSWORD", "MONGO_INITDB_DATABASE")
        case .redis:
            return ("REDIS_USER", "REDIS_PASSWORD", nil)
        }
    }

    var supportsDatabase: Bool {
        self != .redis
    }

    var supportsCustomUser: Bool {
        true
    }

    var defaultContainerPrefix: String {
        switch self {
        case .postgres: "pg"
        case .mysql: "mysql"
        case .mariadb: "mariadb"
        case .mongo: "mongo"
        case .redis: "redis"
        }
    }
}
