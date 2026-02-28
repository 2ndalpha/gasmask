import Foundation
import Sparkle

/// Wraps `SUUpdater.shared()` as an `ObservableObject` for SwiftUI.
///
/// Replaces the XIB-instantiated `SUUpdater` object and `UpdateDateTransformer`.
final class SparkleObserver: ObservableObject {
    @Published var lastCheckDate: Date?
    @Published var automaticChecksEnabled: Bool

    private var dateObservation: NSKeyValueObservation?

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()

    /// Formats `lastCheckDate` as `"Last Checked: Never"` or `"Last Checked: <date>"`.
    var lastCheckDateFormatted: String {
        guard let date = lastCheckDate else {
            return "Last Checked: Never"
        }
        return "Last Checked: \(Self.dateFormatter.string(from: date))"
    }

    init() {
        guard let updater = SUUpdater.shared() else {
            self.lastCheckDate = nil
            self.automaticChecksEnabled = false
            return
        }
        self.lastCheckDate = updater.lastUpdateCheckDate
        self.automaticChecksEnabled = updater.automaticallyChecksForUpdates

        // Observe lastUpdateCheckDate via KVO
        dateObservation = updater.observe(\.lastUpdateCheckDate, options: [.new]) { [weak self] _, change in
            DispatchQueue.main.async {
                self?.lastCheckDate = change.newValue ?? nil
            }
        }
    }

    /// Writes only to UserDefaults — SUUpdater observes this key via its own KVO.
    func setAutomaticChecks(_ enabled: Bool) {
        automaticChecksEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "SUEnableAutomaticChecks")
    }

    func checkForUpdates() {
        SUUpdater.shared()?.checkForUpdates(nil)
    }
}
