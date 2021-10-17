import XCTest
@testable import Mds

class DownloadManagerTestsBase: XCTestCase {
    var cacheMock: RecordCacheMock!
    var target: DownloadManager!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        clearCaches()
        cacheMock = RecordCacheMock(strict: true)
        target = DownloadManager(recordCache: cacheMock, dataReader: DataReaderFromCache())
    }

    func updateState(ofRecord recordId: RecordId, _ newState: RecordCachingState) {
        target.recordCache(cacheMock, didUpdateCachingStateOfRecordWithId: recordId, to: newState)
    }

    private class DataReaderFromCache: DataReader {
        func getAllTracks() -> [MdsTrack] {
            fatalError("DownloadManager is not expected to call `getAllTracks()`")
        }

        func getTotalTrackCount() -> Int {
            fatalError("DownloadManager is not expected to call `getTotalTrackCount()`")
        }

        func getUnfinishedTracks() -> [MdsTrack] {
            fatalError("DownloadManager is not expected to call `getUnfinishedTracks()`")
        }

        func getAllTrackListenInfos() -> [MdsTrackListenInfo] {
            fatalError("DownloadManager is not expected to call `getAllTrackListenInfos()`")
        }

        func getLastTrack() -> (MdsTrack, ServerId)? {
            fatalError("DownloadManager is not expected to call `getLastTrack()`")
        }

        func tryGetRecord(withUrl url: URL) -> MdsRecord? {
            fatalError("DownloadManager is not expected to call `tryGetRecord(withUrl:)`")
        }

        func tryGetTrackListenInfo(forTrack trackId: TrackId) -> MdsTrackListenInfo? {
            fatalError("DownloadManager is not expected to call `tryGetTrackListenInfo(forTrack:)`")
        }

        func tryGetTrack(withId id: TrackId) -> MdsTrack? {
            return trackCache[id]
        }

        func tryGetRecord(withId id: RecordId) -> MdsRecord? {
            return recordCache[id]
        }
    }
}
