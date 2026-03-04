import SwiftUI

enum ContainerState: String, Codable, CaseIterable {
    case running
    case stopped
    case paused
    case restarting
    case removing
    case created
    case exited
    case dead
    case unknown

    init(from status: String) {
        let lower = status.lowercased()
        if lower.contains("up") {
            self = .running
        } else if lower.contains("exited") {
            self = .exited
        } else if lower.contains("paused") {
            self = .paused
        } else if lower.contains("restarting") {
            self = .restarting
        } else if lower.contains("removing") {
            self = .removing
        } else if lower.contains("created") {
            self = .created
        } else if lower.contains("dead") {
            self = .dead
        } else {
            self = .unknown
        }
    }

    var displayName: String {
        switch self {
        case .running: "Running"
        case .stopped: "Stopped"
        case .paused: "Paused"
        case .restarting: "Restarting"
        case .removing: "Removing"
        case .created: "Created"
        case .exited: "Exited"
        case .dead: "Dead"
        case .unknown: "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .running: .green
        case .paused: .orange
        case .restarting: .yellow
        case .stopped, .exited: .secondary
        case .removing, .dead: .red
        case .created, .unknown: .secondary
        }
    }

    var isActive: Bool {
        self == .running || self == .restarting
    }

    var systemImage: String {
        switch self {
        case .running: "circle.fill"
        case .stopped, .exited: "circle"
        case .paused: "pause.circle.fill"
        case .restarting: "arrow.triangle.2.circlepath"
        case .removing: "trash.circle"
        case .created: "circle.dashed"
        case .dead: "xmark.circle.fill"
        case .unknown: "questionmark.circle"
        }
    }
}
