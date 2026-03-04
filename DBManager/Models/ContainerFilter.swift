import SwiftUI

enum ContainerFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case running = "Running"
    case stopped = "Stopped"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .all: .primary
        case .running: .green
        case .stopped: .secondary
        }
    }
}
