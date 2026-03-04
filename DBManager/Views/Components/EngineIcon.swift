import SwiftUI

struct EngineIcon: View {
    let engine: DatabaseEngine
    var size: CGFloat = 32

    var body: some View {
        Image(systemName: engine.iconName)
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(engine.accentColor)
            .frame(width: size, height: size)
            .background(engine.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: size * 0.25))
    }
}

struct EngineIconLarge: View {
    let engine: DatabaseEngine
    var size: CGFloat = 56

    var body: some View {
        Image(systemName: engine.iconName)
            .font(.system(size: size * 0.45, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.22)
                    .fill(
                        LinearGradient(
                            colors: [engine.accentColor, engine.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: engine.accentColor.opacity(0.3), radius: 4, y: 2)
    }
}
