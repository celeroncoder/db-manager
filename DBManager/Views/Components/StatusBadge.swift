import SwiftUI

struct StatusBadge: View {
    let state: ContainerState
    var compact = false

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(state.color)
                .frame(width: compact ? 8 : 10, height: compact ? 8 : 10)
                .shadow(color: state == .running ? .green.opacity(0.5) : .clear, radius: 4)

            if !compact {
                Text(state.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(state.color)
            }
        }
        .padding(.horizontal, compact ? 6 : 10)
        .padding(.vertical, compact ? 3 : 5)
        .background(state.color.opacity(0.12), in: Capsule())
    }
}
