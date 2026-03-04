import SwiftUI

@Observable
final class ContainerListViewModel {
    var searchText = ""
    var sortOrder: SortOrder = .name

    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case engine = "Engine"
        case status = "Status"
        case created = "Created"
    }

    func filtered(_ containers: [DatabaseContainer]) -> [DatabaseContainer] {
        var result = containers

        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.engine.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortOrder {
        case .name:
            result.sort { $0.name < $1.name }
        case .engine:
            result.sort { $0.engine.displayName < $1.engine.displayName }
        case .status:
            result.sort { $0.state.isActive && !$1.state.isActive }
        case .created:
            result.sort { $0.createdAt > $1.createdAt }
        }

        return result
    }
}
