import Foundation

/// Thin ObservableObject wrapper around the existing ObjC `LoginItem` class.
///
/// Delegates all `SMAppService` logic to `LoginItem`, avoiding a parallel implementation.
final class LoginItemObserver: ObservableObject {
    private let loginItem = LoginItem()

    @Published var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            loginItem.setEnabled(isEnabled)
        }
    }

    init() {
        self.isEnabled = loginItem.enabled()
    }
}
