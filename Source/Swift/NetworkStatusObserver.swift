import Foundation
import Combine

final class NetworkStatusObserver: ObservableObject {
    @Published var isOnline: Bool

    private var observation: NSKeyValueObservation?

    init() {
        isOnline = Network.defaultInstance().online
        observation = Network.defaultInstance().observe(\.online, options: [.new]) { [weak self] _, change in
            DispatchQueue.main.async {
                self?.isOnline = change.newValue ?? Network.defaultInstance().online
            }
        }
    }
}
