import SwiftUI

struct URLSheetView: View {
    @State private var urlText: String
    @StateObject private var networkStatus = NetworkStatusObserver()
    @FocusState private var urlFieldFocused: Bool

    var onAdd: (URL) -> Void
    var onCancel: () -> Void

    init(urlText: String = "", onAdd: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
        self._urlText = State(initialValue: urlText)
        self.onAdd = onAdd
        self.onCancel = onCancel
    }

    private var isValidURL: Bool {
        URLValidator.isValid(urlText)
    }

    /// Exposed for testing: reflects the enabled state of the Add button.
    var isAddButtonEnabled: Bool { isValidURL }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("URL:")
                TextField("https://example.com/hosts", text: $urlText)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 300)
                    .focused($urlFieldFocused)
                    .onSubmit {
                        if isValidURL, let url = URL(string: urlText) {
                            onAdd(url)
                        }
                    }
            }

            if !networkStatus.isOnline {
                HStack {
                    Image(systemName: "wifi.slash")
                        .accessibilityHidden(true)
                    Text("You are not connected to the Internet")
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Add") {
                    if isValidURL, let url = URL(string: urlText) {
                        onAdd(url)
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValidURL)
            }
        }
        .padding(20)
        .frame(minWidth: 420)
        .onAppear {
            urlFieldFocused = true
        }
    }
}
