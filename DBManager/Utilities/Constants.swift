import Foundation

enum Constants {
    static let appLabel = "app=db-manager"
    static let labelKey = "app"
    static let labelValue = "db-manager"
    static let engineLabelKey = "db-engine"
    static let portLabelKey = "db-port"
    static let userLabelKey = "db-user"
    static let passwordLabelKey = "db-password"
    static let databaseLabelKey = "db-name"

    static let defaultDatabaseName = "app_db"
    static let defaultUsername = "admin"
    static let defaultPasswordLength = 16

    static let refreshInterval: TimeInterval = 5
    static let logTailCount = 200
}
