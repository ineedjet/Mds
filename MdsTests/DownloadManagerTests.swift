import XCTest
@testable import Mds

class DownloadManagerTests: DownloadManagerTestsBase {
    private func verifyDownloads(_ expectedDownloads: [DownloadItem], file: StaticString = #file, line: UInt = #line) {
        XCTAssertDownloadItems(target.getDownloads(), expectedDownloads, file: file, line: line)
    }

    func testGetDownloads() {
        let track1 = TrackStub()
        let recordId11 = track1.addRecord(fileSize: 4200, serverId: .MdsOnlineRu, partNumber: 1)
        let recordId12 = track1.addRecord(fileSize: 3300, serverId: .MdsOnlineRu, partNumber: 2)
        _ = track1.addRecord(fileSize: 2400, serverId: .KallistoRu, partNumber: 0)

        let track2 = TrackStub()
        let recordId2 = track2.addRecord(fileSize: 1234, serverId: .MdsOnlineRu, partNumber: 0)

        verifyDownloads([])

        updateState(ofRecord: recordId11, .cached(URL(fileURLWithPath: "/file11.mp3"), 100500))
        verifyDownloads([
            DownloadItem(trackId: track1.trackId, state: .incomplete(.MdsOnlineRu, getProgress(42, 42+33))),
            ])

        updateState(ofRecord: recordId2, .caching(getProgress(10, 20)))
        verifyDownloads([
            DownloadItem(trackId: track2.trackId, state: .downloading(.MdsOnlineRu, getProgress(1, 2))),
            DownloadItem(trackId: track1.trackId, state: .incomplete(.MdsOnlineRu, getProgress(42, 42+33))),
            ])

        updateState(ofRecord: recordId12, .caching(getProgress(10, 30)))
        verifyDownloads([
            DownloadItem(trackId: track2.trackId, state: .downloading(.MdsOnlineRu, getProgress(1, 2))),
            DownloadItem(trackId: track1.trackId, state: .downloading(.MdsOnlineRu, getProgress(42+11, 42+33))),
            ])

        updateState(ofRecord: recordId2, .cached(URL(fileURLWithPath: "/file2.mp3"), 1234))
        let expectedTrack2State: DownloadState = .downloaded(.MdsOnlineRu, 1234)
        verifyDownloads([
            DownloadItem(trackId: track2.trackId, state: expectedTrack2State),
            DownloadItem(trackId: track1.trackId, state: .downloading(.MdsOnlineRu, getProgress(42+11, 42+33))),
            ])

        updateState(ofRecord: recordId11, .notCached)
        verifyDownloads([
            DownloadItem(trackId: track2.trackId, state: expectedTrack2State),
            DownloadItem(trackId: track1.trackId, state: .downloading(.MdsOnlineRu, getProgress(11, 42+33))),
            ])

        updateState(ofRecord: recordId12, .notCached)
        verifyDownloads([
            DownloadItem(trackId: track2.trackId, state: expectedTrack2State),
            ])

        updateState(ofRecord: recordId12, .caching(getProgress(20, 30)))
        verifyDownloads([
            DownloadItem(trackId: track1.trackId, state: .downloading(.MdsOnlineRu, getProgress(22, 42+33))),
            DownloadItem(trackId: track2.trackId, state: expectedTrack2State),
            ])

        updateState(ofRecord: recordId12, .cached(URL(fileURLWithPath: "/file12.mp3"), 3300))
        verifyDownloads([
            DownloadItem(trackId: track1.trackId, state: .incomplete(.MdsOnlineRu, getProgress(33, 42+33))),
            DownloadItem(trackId: track2.trackId, state: expectedTrack2State),
            ])

        updateState(ofRecord: recordId12, .notCached)
        verifyDownloads([
            DownloadItem(trackId: track2.trackId, state: expectedTrack2State),
            ])
    }

    func testEstimateSizePositive() {
        let track1 = TrackStub()
        let recordId11 = track1.addRecord(fileSize: 4200, serverId: .MdsOnlineRu, partNumber: 1)
        let recordId12 = track1.addRecord(fileSize: 3300, serverId: .MdsOnlineRu, partNumber: 2)
        _ = track1.addRecord(fileSize: 2400, serverId: .KallistoRu, partNumber: 0)

        var callbackResult: Int64? = nil
        var callbackCalledTimes = 0
        target.estimateSize(ofTrack: track1, fromServer: .MdsOnlineRu) { size in
            callbackResult = size
            callbackCalledTimes += 1
        }

        XCTAssertEqual(callbackCalledTimes, 0)
        let requests = cacheMock.estimateSizeRequests
        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(requests[0].0.recordId, recordId11)
        XCTAssertEqual(requests[1].0.recordId, recordId12)

        requests[0].1(42)
        XCTAssertEqual(callbackCalledTimes, 0)
        XCTAssertEqual(cacheMock.estimateSizeRequests.count, 2) // no new requests

        requests[1].1(18)
        XCTAssertEqual(callbackCalledTimes, 1)
        XCTAssertEqual(callbackResult, 60)
        XCTAssertEqual(cacheMock.estimateSizeRequests.count, 2) // no new requests
    }

    func testEstimateSizeFirstFailed() {
        let track1 = TrackStub()
        let recordId11 = track1.addRecord(fileSize: 4200, serverId: .MdsOnlineRu, partNumber: 1)
        let recordId12 = track1.addRecord(fileSize: 3300, serverId: .MdsOnlineRu, partNumber: 2)
        _ = track1.addRecord(fileSize: 2400, serverId: .KallistoRu, partNumber: 0)

        var callbackResult: Int64? = nil
        var callbackCalledTimes = 0
        target.estimateSize(ofTrack: track1, fromServer: .MdsOnlineRu) { size in
            callbackResult = size
            callbackCalledTimes += 1
        }

        XCTAssertEqual(callbackCalledTimes, 0)
        let requests = cacheMock.estimateSizeRequests
        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(requests[0].0.recordId, recordId11)
        XCTAssertEqual(requests[1].0.recordId, recordId12)

        requests[0].1(nil)
        XCTAssertEqual(callbackCalledTimes, 1)
        XCTAssertEqual(callbackResult, nil)
        XCTAssertEqual(cacheMock.estimateSizeRequests.count, 2) // no new requests

        requests[1].1(18)
        XCTAssertEqual(callbackCalledTimes, 1) // no new callbacks
        XCTAssertEqual(cacheMock.estimateSizeRequests.count, 2) // no new requests
    }

    func testEstimateSizeSecondFailed() {
        let track1 = TrackStub()
        let recordId11 = track1.addRecord(fileSize: 4200, serverId: .MdsOnlineRu, partNumber: 1)
        let recordId12 = track1.addRecord(fileSize: 3300, serverId: .MdsOnlineRu, partNumber: 2)
        _ = track1.addRecord(fileSize: 2400, serverId: .KallistoRu, partNumber: 0)

        var callbackResult: Int64? = nil
        var callbackCalledTimes = 0
        target.estimateSize(ofTrack: track1, fromServer: .MdsOnlineRu) { size in
            callbackResult = size
            callbackCalledTimes += 1
        }

        XCTAssertEqual(callbackCalledTimes, 0)
        let requests = cacheMock.estimateSizeRequests
        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(requests[0].0.recordId, recordId11)
        XCTAssertEqual(requests[1].0.recordId, recordId12)

        requests[0].1(42)
        XCTAssertEqual(callbackCalledTimes, 0)
        XCTAssertEqual(cacheMock.estimateSizeRequests.count, 2) // no new requests

        requests[1].1(nil)
        XCTAssertEqual(callbackCalledTimes, 1)
        XCTAssertEqual(callbackResult, nil)
        XCTAssertEqual(cacheMock.estimateSizeRequests.count, 2) // no new requests
    }

    func testEstimateSizeBothFailed() {
        let track1 = TrackStub()
        let recordId11 = track1.addRecord(fileSize: 4200, serverId: .MdsOnlineRu, partNumber: 1)
        let recordId12 = track1.addRecord(fileSize: 3300, serverId: .MdsOnlineRu, partNumber: 2)
        _ = track1.addRecord(fileSize: 2400, serverId: .KallistoRu, partNumber: 0)

        var callbackResult: Int64? = nil
        var callbackCalledTimes = 0
        target.estimateSize(ofTrack: track1, fromServer: .MdsOnlineRu) { size in
            callbackResult = size
            callbackCalledTimes += 1
        }

        XCTAssertEqual(callbackCalledTimes, 0)
        let requests = cacheMock.estimateSizeRequests
        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(requests[0].0.recordId, recordId11)
        XCTAssertEqual(requests[1].0.recordId, recordId12)

        requests[0].1(nil)
        XCTAssertEqual(callbackCalledTimes, 1)
        XCTAssertEqual(callbackResult, nil)
        XCTAssertEqual(cacheMock.estimateSizeRequests.count, 2) // no new requests

        requests[1].1(nil)
        XCTAssertEqual(callbackCalledTimes, 1)
        XCTAssertEqual(cacheMock.estimateSizeRequests.count, 2) // no new requests
    }
}
