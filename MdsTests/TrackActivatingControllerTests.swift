import XCTest
@testable import Mds

fileprivate extension Int {
    var KB: Int64 {
        return Int64(self) * 1024
    }
    var MB: Int64 {
        return Int64(self) * 1024 * 1024
    }
}

class TrackActivatingControllerTests: XCTestCase {
    private var dmSpy: DownloadManagerSpy!
    private var delegateSpy: TrackActivatingDelegateSpy!
    private var audioSpy: AudioPlayerSpy!
    private var target: TrackActivatingController!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        dmSpy = DownloadManagerSpy()
        delegateSpy = TrackActivatingDelegateSpy()
        audioSpy = AudioPlayerSpy()

        target = TrackActivatingController(audioPlayer: audioSpy, downloadManager: dmSpy)
        target.delegate = delegateSpy
        verify()
    }

    private func waitForMainQueue() {
        let mainQueueFinished = expectation(description: "Main queue finished processing")
        DispatchQueue.main.async { mainQueueFinished.fulfill() }
        wait(for: [mainQueueFinished], timeout: 1)
    }

    func testIsComparable() {
        XCTAssertEqual(isComparable(fileSize: 95, toExpectedSize: 100), true)
        XCTAssertEqual(isComparable(fileSize: 150, toExpectedSize: 100), true)
        XCTAssertEqual(isComparable(fileSize: 1.MB, toExpectedSize: 100), true)
        XCTAssertEqual(isComparable(fileSize: 5.MB, toExpectedSize: 100), true)
        XCTAssertEqual(isComparable(fileSize: 6.MB, toExpectedSize: 100), false)
        XCTAssertEqual(isComparable(fileSize: 10.MB, toExpectedSize: 100), false)

        XCTAssertEqual(isComparable(fileSize: 950.KB, toExpectedSize: 1.MB), true)
        XCTAssertEqual(isComparable(fileSize: 1100.KB, toExpectedSize: 1.MB), true)
        XCTAssertEqual(isComparable(fileSize: 5.MB, toExpectedSize: 1.MB), true)
        XCTAssertEqual(isComparable(fileSize: 10.MB, toExpectedSize: 1.MB), false)

        XCTAssertEqual(isComparable(fileSize: 95.MB, toExpectedSize: 100.MB), true)
        XCTAssertEqual(isComparable(fileSize: 110.MB, toExpectedSize: 100.MB), true)
        XCTAssertEqual(isComparable(fileSize: 120.MB, toExpectedSize: 100.MB), false)

        XCTAssertEqual(isComparable(fileSize: 950.MB, toExpectedSize: 1024.MB), true)
        XCTAssertEqual(isComparable(fileSize: 1100.MB, toExpectedSize: 1024.MB), true)
        XCTAssertEqual(isComparable(fileSize: 1200.MB, toExpectedSize: 1024.MB), true)
        XCTAssertEqual(isComparable(fileSize: 1230.MB, toExpectedSize: 1024.MB), false)
    }

    private func verify(
        estimateSizeRequests: [(MdsTrack, ServerId)] = [],
        preparedForDownload: Set<TrackId> = [],
        downloadRequests: [(MdsTrack, ServerId, Bool)] = [],
        reportedErrors: Int = 0,
        downloadConfirmationRequests: [(MdsTrack, Int64)] = [],
        file: StaticString = #file,
        line: UInt = #line
        ) {
        XCTAssertEstimateSizeRequests(dmSpy, estimateSizeRequests, file: file, line: line)
        XCTAssertSet(dmSpy.preparedForDownload, preparedForDownload, file: file, line: line)
        XCTAssertDownloadRequests(dmSpy, downloadRequests, file: file, line: line)
        XCTAssertEqual(delegateSpy.reportedErrors.count, reportedErrors, file: file, line: line)
        for error in delegateSpy.reportedErrors {
            XCTAssertNotEqual(error.localizedDescription, "", "Missing error description", file: file, line: line)
        }
        XCTAssertDownloadConfirmationRequests(delegateSpy, downloadConfirmationRequests, file: file, line: line)
    }

    private func provideSizeEstimate(_ size: Int64?) {
        dmSpy.provideSizeEstimate(size)
        target?.waitForTheBackgroundQueue()
        waitForMainQueue()
    }

    private func replyYes() {
        delegateSpy.reply(confirm: true)
        target?.waitForTheBackgroundQueue()
        waitForMainQueue()
    }

    private func replyNo() {
        delegateSpy.reply(confirm: false)
        target?.waitForTheBackgroundQueue()
        waitForMainQueue()
    }

    func testProcessActionCompleteDownload() {
        let track = TrackStub()
        target.processAction(.completeDownloadFromServer(.ArchiveOrg2015, 100500), forTrack: track)
        verify(
            downloadRequests: [(track, .ArchiveOrg2015, false)])
    }

    func testProcessActionNoServers() {
        let track = TrackStub()
        _ = track.addRecord(fileSize: 1.MB, serverId: .MdsOnlineRu, partNumber: 0)
        _ = track.addRecord(fileSize: 2.MB, serverId: .KallistoRu, partNumber: 0)
        target.processAction(.download(track.getServersWithSizes()), forTrack: track)
        verify(
            estimateSizeRequests: [(track, .MdsOnlineRu)],
            preparedForDownload: [track.trackId])

        provideSizeEstimate(nil)
        verify(
            estimateSizeRequests: [(track, .KallistoRu)],
            preparedForDownload: [track.trackId])

        provideSizeEstimate(nil)
        verify(
            reportedErrors: 1)
    }

    func testProcessActionFirstServerOkSize() {
        let track = TrackStub()
        _ = track.addRecord(fileSize: 1.MB, serverId: .MdsOnlineRu, partNumber: 0)
        _ = track.addRecord(fileSize: 2.MB, serverId: .KallistoRu, partNumber: 0)
        target.processAction(.download(track.getServersWithSizes()), forTrack: track)
        verify(
            estimateSizeRequests: [(track, .MdsOnlineRu)],
            preparedForDownload: [track.trackId])

        provideSizeEstimate(1.MB)
        verify(
            downloadRequests: [(track, .MdsOnlineRu, true)])
    }

    func testProcessActionFirstServerConfirmSizeYes() {
        let track = TrackStub()
        _ = track.addRecord(fileSize: 1.MB, serverId: .MdsOnlineRu, partNumber: 0)
        _ = track.addRecord(fileSize: 2.MB, serverId: .KallistoRu, partNumber: 0)
        target.processAction(.download(track.getServersWithSizes()), forTrack: track)
        verify(
            estimateSizeRequests: [(track, .MdsOnlineRu)],
            preparedForDownload: [track.trackId])

        provideSizeEstimate(50.MB) // way larger than expected
        verify(
            preparedForDownload: [track.trackId],
            downloadConfirmationRequests: [(track, 50.MB)])

        replyYes()
        verify(
            downloadRequests: [(track, .MdsOnlineRu, true)])
    }

    func testProcessActionFirstServerConfirmSizeNo() {
        let track = TrackStub()
        _ = track.addRecord(fileSize: 1.MB, serverId: .MdsOnlineRu, partNumber: 0)
        _ = track.addRecord(fileSize: 2.MB, serverId: .KallistoRu, partNumber: 0)
        target.processAction(.download(track.getServersWithSizes()), forTrack: track)
        verify(
            estimateSizeRequests: [(track, .MdsOnlineRu)],
            preparedForDownload: [track.trackId])

        provideSizeEstimate(50.MB) // way larger than expected
        verify(
            preparedForDownload: [track.trackId],
            downloadConfirmationRequests: [(track, 50.MB)])

        replyNo()
        verify()
    }

    func testProcessActionSecondServerConfirmSizeYes() {
        let track = TrackStub()
        _ = track.addRecord(fileSize: 1.MB, serverId: .MdsOnlineRu, partNumber: 0)
        _ = track.addRecord(fileSize: 2.MB, serverId: .KallistoRu, partNumber: 0)
        target.processAction(.download(track.getServersWithSizes()), forTrack: track)
        verify(
            estimateSizeRequests: [(track, .MdsOnlineRu)],
            preparedForDownload: [track.trackId])

        provideSizeEstimate(nil)
        verify(
            estimateSizeRequests: [(track, .KallistoRu)],
            preparedForDownload: [track.trackId])

        provideSizeEstimate(50.MB) // way larger than expected
        verify(
            preparedForDownload: [track.trackId],
            downloadConfirmationRequests: [(track, 50.MB)])

        replyYes()
        verify(
            downloadRequests: [(track, .KallistoRu, true)])
    }

    func testProcessActionSecondServerConfirmSizeNo() {
        let track = TrackStub()
        _ = track.addRecord(fileSize: 1.MB, serverId: .MdsOnlineRu, partNumber: 0)
        _ = track.addRecord(fileSize: 2.MB, serverId: .KallistoRu, partNumber: 0)
        target.processAction(.download(track.getServersWithSizes()), forTrack: track)
        verify(
            estimateSizeRequests: [(track, .MdsOnlineRu)],
            preparedForDownload: [track.trackId])

        provideSizeEstimate(nil)
        verify(
            estimateSizeRequests: [(track, .KallistoRu)],
            preparedForDownload: [track.trackId])

        provideSizeEstimate(50.MB) // way larger than expected
        verify(
            preparedForDownload: [track.trackId],
            downloadConfirmationRequests: [(track, 50.MB)])

        replyNo()
        verify()
    }

    func testProcessActionCancelBeforeReply() {
        let track = TrackStub()
        _ = track.addRecord(fileSize: 1.MB, serverId: .MdsOnlineRu, partNumber: 0)
        _ = track.addRecord(fileSize: 2.MB, serverId: .KallistoRu, partNumber: 0)
        target.processAction(.download(track.getServersWithSizes()), forTrack: track)
        verify(
            estimateSizeRequests: [(track, .MdsOnlineRu)],
            preparedForDownload: [track.trackId])

        target.processAction(.cancelDownload, forTrack: track)
        verify(
            estimateSizeRequests: [(track, .MdsOnlineRu)])

        provideSizeEstimate(1.MB)
        verify(
            downloadRequests: [(track, .MdsOnlineRu, true)]) // download manager will reject because onlyIfPrepared is set
    }

    func testProcessActionDestroyedBeforeBothReplies() {
        let track = TrackStub()
        _ = track.addRecord(fileSize: 1.MB, serverId: .MdsOnlineRu, partNumber: 0)
        _ = track.addRecord(fileSize: 2.MB, serverId: .KallistoRu, partNumber: 0)
        target.processAction(.download(track.getServersWithSizes()), forTrack: track)
        verify(
            estimateSizeRequests: [(track, .MdsOnlineRu)],
            preparedForDownload: [track.trackId])

        target = nil
        provideSizeEstimate(nil)
        verify(
            estimateSizeRequests: [(track, .KallistoRu)],
            preparedForDownload: [track.trackId])

        provideSizeEstimate(nil)
        verify()
    }

    func testProcessActionDestroyedBeforeFirstSuccessReply() {
        let track = TrackStub()
        _ = track.addRecord(fileSize: 1.MB, serverId: .MdsOnlineRu, partNumber: 0)
        _ = track.addRecord(fileSize: 2.MB, serverId: .KallistoRu, partNumber: 0)
        target.processAction(.download(track.getServersWithSizes()), forTrack: track)
        verify(
            estimateSizeRequests: [(track, .MdsOnlineRu)],
            preparedForDownload: [track.trackId])

        target = nil
        provideSizeEstimate(1.MB)
        verify(
            downloadRequests: [(track, .MdsOnlineRu, true)]) // download anyway, we don't care about the controller
    }

    func testProcessActionDestroyedBeforeFirstConfirmationReply() {
        let track = TrackStub()
        _ = track.addRecord(fileSize: 1.MB, serverId: .MdsOnlineRu, partNumber: 0)
        _ = track.addRecord(fileSize: 2.MB, serverId: .KallistoRu, partNumber: 0)
        target.processAction(.download(track.getServersWithSizes()), forTrack: track)
        verify(
            estimateSizeRequests: [(track, .MdsOnlineRu)],
            preparedForDownload: [track.trackId])

        target = nil
        provideSizeEstimate(50.MB) // way larger than expected
        verify()
    }

    func testProcessActionDestroyedBeforeSecondReply() {
        let track = TrackStub()
        _ = track.addRecord(fileSize: 1.MB, serverId: .MdsOnlineRu, partNumber: 0)
        _ = track.addRecord(fileSize: 2.MB, serverId: .KallistoRu, partNumber: 0)
        target.processAction(.download(track.getServersWithSizes()), forTrack: track)
        verify(
            estimateSizeRequests: [(track, .MdsOnlineRu)],
            preparedForDownload: [track.trackId])

        provideSizeEstimate(nil)
        verify(
            estimateSizeRequests: [(track, .KallistoRu)],
            preparedForDownload: [track.trackId])

        target = nil
        provideSizeEstimate(nil)
        verify()
    }
}
