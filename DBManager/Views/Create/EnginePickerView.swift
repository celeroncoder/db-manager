import SwiftUI

struct EnginePickerView: View {
    @Binding var selected: DatabaseEngine

    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(DatabaseEngine.allCases) { engine in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selected = engine
                    }
                } label: {
                    EnginePickerCard(engine: engine, isSelected: selected == engine)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(engine.displayName) database engine")
                .accessibilityAddTraits(selected == engine ? .isSelected : [])
            }
        }
    }
}

struct EnginePickerCard: View {
    let engine: DatabaseEngine
    let isSelected: Bool
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 10) {
            EngineIconLarge(engine: engine, size: 48)

            Text(engine.displayName)
                .font(.callout)
                .fontWeight(.medium)

            Text(engine.dockerImage)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? engine.accentColor.opacity(0.1) : Color(.controlBackgroundColor))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isSelected ? engine.accentColor : (isHovered ? Color.secondary.opacity(0.3) : .clear),
                    lineWidth: isSelected ? 2 : 1
                )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isSelected)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
