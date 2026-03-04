import SwiftUI
import AppKit

struct CopyButton: View {
    let text: String
    var label: String? = nil
    @State private var copied = false

    var body: some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            withAnimation(.easeInOut(duration: 0.2)) {
                copied = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    copied = false
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(copied ? .green : .secondary)
                    .contentTransition(.symbolEffect(.replace))

                if let label {
                    Text(copied ? "Copied!" : label)
                        .font(.caption)
                        .foregroundStyle(copied ? .green : .secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .help("Copy to clipboard")
        .accessibilityLabel(copied ? "Copied" : "Copy to clipboard")
    }
}
