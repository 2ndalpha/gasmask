import SwiftUI

struct URLSheetView: View {
    @State private var urlText = ""
    @StateObject private var networkStatus = NetworkStatusObserver()
    @FocusState private var urlFieldFocused: Bool

    var onAdd: (URL) -> Void
    var onCancel: () -> Void

    private var isValidURL: Bool {
        URLValidator.isValid(urlText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                    if let url = URL(string: urlText) {
                        onAdd(url)
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValidURL)
            }
        }
        .padding()
        .frame(minWidth: 400)
        .onAppear {
            urlFieldFocused = true
        }
    }
}
