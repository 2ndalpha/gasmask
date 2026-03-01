import SwiftUI

struct EditorView: View {
    @StateObject private var store = HostsDataStore()

    var body: some View {
        NavigationSplitView {
            SidebarView(store: store)
                .navigationSplitViewColumnWidth(min: 140, ideal: 160, max: 300)
        } detail: {
            ContentView(store: store)
        }
        .toolbar { EditorToolbar(store: store) }
        .safeAreaInset(edge: .bottom) { StatusBarView(store: store) }
    }
}
