import Foundation

enum URLValidator {
    static func isValid(_ string: String) -> Bool {
        (string.hasPrefix("http://") || string.hasPrefix("https://")) &&
            URL(string: string) != nil
    }
}
