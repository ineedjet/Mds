import XCTest
@testable import Mds

fileprivate extension Double {
    var seconds: TimeInterval { self }
    var minutes: TimeInterval { self * 60 }
    var hours: TimeInterval { self * 3600 }
    var days: TimeInterval { self * 24 * 3600 }
}

fileprivate let tenAMtoday: Date = Calendar.current.startOfDay(for: Date()).addingTimeInterval(10.hours)
fileprivate let nineAMtoday: Date = tenAMtoday.addingTimeInterval(-1.hours)
fileprivate let eightAMtoday: Date = nineAMtoday.addingTimeInterval(-1.hours)
fileprivate let elevenAMtoday: Date = tenAMtoday.addingTimeInterval(1.hours)
fileprivate let tenAMyesterday: Date = tenAMtoday.addingTimeInterval(-1.days)
fileprivate let tenAMdayBeforeYesterday: Date = tenAMtoday.addingTimeInterval(-2.days)

class RecentsControllerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DataStorage.initializeForUnitTests()
        continueAfterFailure = false
    }

    func testRows() {
        let controller = RecentsController()
        XCTAssertEqual(controller.headerField, .lastListened)
        XCTAssertEqual(controller.numberOfSections(), 0)

        let tracks = DataStorage.reader.getAllTracks()
        XCTAssertGreaterThanOrEqual(tracks.count, 2, "Not enough tracks for this test")

        DataStorage.writer.set(lastListened: nineAMtoday, forTrack: tracks[0])
        XCTAssertEqual(controller.numberOfSections(), 1)
        XCTAssertEqual(controller.numberOfRows(inSection: 0), 1)
        XCTAssertNotNil(controller.titleForHeader(inSection: 0))
        XCTAssertEqual(controller[IndexPath(row: 0, section: 0)]?.trackId, tracks[0].trackId)

        DataStorage.writer.set(lastListened: tenAMtoday, forTrack: tracks[1])
        XCTAssertEqual(controller.numberOfSections(), 1)
        XCTAssertEqual(controller.numberOfRows(inSection: 0), 2)
        XCTAssertNotNil(controller.titleForHeader(inSection: 0))
        XCTAssertEqual(controller[IndexPath(row: 0, section: 0)]?.trackId, tracks[1].trackId)
        XCTAssertEqual(controller[IndexPath(row: 1, section: 0)]?.trackId, tracks[0].trackId)

        XCTAssertNil(controller.sectionIndexTitles())
        XCTAssertNil(controller.section(forSectionIndexTitle: "", at: 0))
    }

    func testSections() {
        let controller = RecentsController()

        let tracks = DataStorage.reader.getAllTracks()
        XCTAssertGreaterThanOrEqual(tracks.count, 3, "Not enough tracks for this test")

        DataStorage.writer.set(lastListened: tenAMtoday, forTrack: tracks[0])
        XCTAssertEqual(controller.numberOfSections(), 1)

        DataStorage.writer.set(lastListened: tenAMyesterday, forTrack: tracks[1])
        XCTAssertEqual(controller.numberOfSections(), 2)
        XCTAssertEqual(controller.numberOfRows(inSection: 0), 1)
        XCTAssertEqual(controller.numberOfRows(inSection: 1), 1)
        XCTAssertEqual(controller[IndexPath(row: 0, section: 0)]?.trackId, tracks[0].trackId)
        XCTAssertEqual(controller[IndexPath(row: 0, section: 1)]?.trackId, tracks[1].trackId)

        DataStorage.writer.set(lastListened: tenAMdayBeforeYesterday, forTrack: tracks[2])
        XCTAssertEqual(controller.numberOfSections(), 3)
        XCTAssertEqual(controller.numberOfRows(inSection: 0), 1)
        XCTAssertEqual(controller.numberOfRows(inSection: 1), 1)
        XCTAssertEqual(controller.numberOfRows(inSection: 2), 1)
        XCTAssertEqual(controller[IndexPath(row: 0, section: 0)]?.trackId, tracks[0].trackId)
        XCTAssertEqual(controller[IndexPath(row: 0, section: 1)]?.trackId, tracks[1].trackId)
        XCTAssertEqual(controller[IndexPath(row: 0, section: 2)]?.trackId, tracks[2].trackId)
    }

    func testNotifications() {
        let controller = RecentsController()
        let delegateSpy = TrackListControllerDelegateSpy()
        controller.delegate = delegateSpy
        XCTAssertEqual(controller.numberOfSections(), 0)

        let tracks = DataStorage.reader.getAllTracks()
        XCTAssertGreaterThanOrEqual(tracks.count, 3, "Not enough tracks for this test")

        delegateSpy.verifyAndReset(drasticDataChangeRequests: 0)
        DataStorage.writer.set(lastListened: eightAMtoday, forTrack: tracks[0])
        delegateSpy.verifyAndReset(drasticDataChangeRequests: 1)
        XCTAssertEqual(controller.numberOfSections(), 1)
        XCTAssertEqual(controller.numberOfRows(inSection: 0), 1)

        DataStorage.writer.set(lastListened: nineAMtoday, forTrack: tracks[1])
        delegateSpy.verifyAndReset(drasticDataChangeRequests: 1)
        XCTAssertEqual(controller.numberOfSections(), 1)
        XCTAssertEqual(controller.numberOfRows(inSection: 0), 2)

        DataStorage.writer.set(lastListened: tenAMtoday, forTrack: tracks[0])
        delegateSpy.verifyAndReset(drasticDataChangeRequests: 1)
        XCTAssertEqual(controller.numberOfSections(), 1)
        XCTAssertEqual(controller.numberOfRows(inSection: 0), 2)

        DataStorage.writer.set(lastListened: tenAMyesterday, forTrack: tracks[2])
        delegateSpy.verifyAndReset(drasticDataChangeRequests: 1)
        XCTAssertEqual(controller.numberOfSections(), 2)
        XCTAssertEqual(controller.numberOfRows(inSection: 0), 2)
        XCTAssertEqual(controller.numberOfRows(inSection: 1), 1)

        DataStorage.writer.set(lastListened: elevenAMtoday, forTrack: tracks[2])
        delegateSpy.verifyAndReset(drasticDataChangeRequests: 1)
        XCTAssertEqual(controller.numberOfSections(), 1)
        XCTAssertEqual(controller.numberOfRows(inSection: 0), 3)
    }
}
