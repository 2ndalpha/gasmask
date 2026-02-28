import Foundation

/// Maps slider positions (1–9) to remote update intervals in minutes.
///
/// Extracted from the ObjC `PreferenceController (Remote)` category for testability.
/// The same minute values are stored in UserDefaults and read by `GlobalHotkeys`.
enum RemoteIntervalMapper {
    static let intervals: [(position: Int, minutes: Int)] = [
        (1, 5),
        (2, 15),
        (3, 30),
        (4, 60),
        (5, 120),
        (6, 300),
        (7, 600),
        (8, 1440),
        (9, 10080),
    ]

    /// Display labels for each slider tick mark, matching the 9 positions.
    static let labels: [String] = ["5m", "15m", "30m", "1h", "2h", "5h", "10h", "24h", "7d"]

    /// Returns the interval in minutes for a given slider position (1–9).
    static func minutes(forPosition position: Int) -> Int {
        intervals.first { $0.position == position }?.minutes ?? 5
    }

    /// Returns the slider position (1–9) for a given interval in minutes.
    ///
    /// Returns `1` for unknown values — an intentional improvement over the ObjC code
    /// which returned `0` (below the slider's minimum), causing an impossible state.
    static func position(forMinutes minutes: Int) -> Int {
        intervals.first { $0.minutes == minutes }?.position ?? 1
    }
}
