import SwiftUI

struct ContentView: View {
    @ObservedObject var store: HostsDataStore

    var body: some View {
        VStack(spacing: 0) {
            if store.selectedHosts is CombinedHosts {
                CombinedHostsPickerView(store: store)
                Divider()
            }
            HostsTextViewRepresentable(
                selectedHosts: store.selectedHosts,
                contentToken: store.rowRefreshToken,
                onTextChange: { [weak store] newText in
                    store?.selectedHosts?.setContents(newText)
                }
            )
        }
    }
}
