import XCTest
@testable import Mds

class CustomAssertTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func _testInvalidCount() {
        XCTAssertDownloadItems([DownloadItem(trackId: 1, state: .notDownloaded)], [])
    }

    func _testInvalidTrackId() {
        XCTAssertDownloadItems(
            [DownloadItem(trackId: 1, state: .notDownloaded)],
            [DownloadItem(trackId: 2, state: .notDownloaded)]
        )
    }

    func _testStateNotNotDownloaded() {
        XCTAssertDownloadItems(
            [DownloadItem(trackId: 1, state: .corrupted(1))],
            [DownloadItem(trackId: 1, state: .notDownloaded)]
        )
    }

    func testStateNotDownloaded() {
        XCTAssertDownloadItems(
            [DownloadItem(trackId: 1, state: .notDownloaded)],
            [DownloadItem(trackId: 1, state: .notDownloaded)]
        )
    }

    func _testStateNotCorrupted() {
        XCTAssertDownloadItems(
            [DownloadItem(trackId: 1, state: .notDownloaded)],
            [DownloadItem(trackId: 1, state: .corrupted(1))]
        )
    }

    func testStateCorrupted() {
        XCTAssertDownloadItems(
            [DownloadItem(trackId: 1, state: .corrupted(1))],
            [DownloadItem(trackId: 1, state: .corrupted(1))]
        )
    }

    func _testStateCorruptedDifferent() {
        XCTAssertDownloadItems(
            [DownloadItem(trackId: 1, state: .corrupted(1))],
            [DownloadItem(trackId: 1, state: .corrupted(2))]
        )
    }
}
