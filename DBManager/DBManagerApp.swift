import SwiftUI

@main
struct DBManagerApp: App {
    @State private var appVM = AppViewModel()

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
