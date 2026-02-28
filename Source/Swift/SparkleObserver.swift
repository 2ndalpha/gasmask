import Combine
import Foundation
import Sparkle

/// Wraps `SPUUpdater` as an `ObservableObject` for SwiftUI.
final class SparkleObserver: ObservableObject {
    @Published var lastCheckDate: Date?
    @Published var automaticChecksEnabled: Bool
    @Published var canCheckForUpdates = false

    private let updater: SPUUpdater?

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

    convenience init() {
        self.init(updater: ApplicationController.defaultInstance()?.updater)
    }

    init(updater: SPUUpdater?) {
        self.updater = updater
        self.lastCheckDate = updater?.lastUpdateCheckDate
        self.automaticChecksEnabled = updater?.automaticallyChecksForUpdates ?? false

        guard let updater else { return }

        updater.publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .assign(to: &$canCheckForUpdates)

        updater.publisher(for: \.automaticallyChecksForUpdates)
            .receive(on: DispatchQueue.main)
            .assign(to: &$automaticChecksEnabled)

        updater.publisher(for: \.lastUpdateCheckDate)
            .receive(on: DispatchQueue.main)
            .assign(to: &$lastCheckDate)
    }

    func setAutomaticChecks(_ enabled: Bool) {
        if let updater {
            updater.automaticallyChecksForUpdates = enabled
        } else {
            automaticChecksEnabled = enabled
        }
    }

    func checkForUpdates() {
        guard let updater, updater.canCheckForUpdates else { return }
        updater.checkForUpdates()
    }
}
