import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        @Bindable var appVM = appVM

        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            if let container = appVM.selectedContainer {
                ContainerDetailView(container: container)
            } else {
                DashboardView()
            }
        }
        .sheet(isPresented: $appVM.showCreateSheet) {
            CreateDatabaseSheet()
        }
        .alert("Error", isPresented: .init(
            get: { appVM.errorMessage != nil },
            set: { if !$0 { appVM.errorMessage = nil } }
        )) {
            Button("OK") {
                appVM.errorMessage = nil
            }
        } message: {
            Text(appVM.errorMessage ?? "")
        }
    }
}
