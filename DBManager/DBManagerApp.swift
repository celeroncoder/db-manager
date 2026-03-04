import SwiftUI
import AppKit

@main
struct DBManagerApp: App {
    @State private var appVM = AppViewModel()

    init() {
        // Set app icon from bundled resource
        let bundle = Bundle.module
        if let url = bundle.url(forResource: "icon_1024", withExtension: "png", subdirectory: "Assets.xcassets/AppIcon.appiconset"),
           let icon = NSImage(contentsOf: url) {
            NSApplication.shared.applicationIconImage = icon
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appVM)
                .task {
                    await appVM.startPolling()
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1100, height: 700)
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Database") {
                    appVM.showCreateSheet = true
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Refresh") {
                    Task { await appVM.refresh() }
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}
