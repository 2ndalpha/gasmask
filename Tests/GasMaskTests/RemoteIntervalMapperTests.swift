import XCTest
@testable import Gas_Mask

final class RemoteIntervalMapperTests: XCTestCase {

    func testAllForwardMappings() {
        let expected: [(position: Int, minutes: Int)] = [
            (1, 5), (2, 15), (3, 30), (4, 60), (5, 120),
            (6, 300), (7, 600), (8, 1440), (9, 10080),
        ]
        for (position, minutes) in expected {
            XCTAssertEqual(
                RemoteIntervalMapper.minutes(forPosition: position), minutes,
                "Position \(position) should map to \(minutes) minutes"
            )
        }
    }

    func testAllReverseMappings() {
        let expected: [(minutes: Int, position: Int)] = [
            (5, 1), (15, 2), (30, 3), (60, 4), (120, 5),
            (300, 6), (600, 7), (1440, 8), (10080, 9),
        ]
        for (minutes, position) in expected {
            XCTAssertEqual(
                RemoteIntervalMapper.position(forMinutes: minutes), position,
                "\(minutes) minutes should map to position \(position)"
            )
        }
    }

    func testUnknownMinutes_fallsBackToPosition1() {
        XCTAssertEqual(RemoteIntervalMapper.position(forMinutes: 999), 1)
        XCTAssertEqual(RemoteIntervalMapper.position(forMinutes: 0), 1)
        XCTAssertEqual(RemoteIntervalMapper.position(forMinutes: -1), 1)
    }

    func testLabels_hasNineElements() {
        XCTAssertEqual(RemoteIntervalMapper.labels.count, 9)
    }
}
