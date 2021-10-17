import XCTest
@testable import Mds

class DownloadManagerGetStateTests: DownloadManagerTestsBase {
    private func assertState(ofTrack track: MdsTrack, _ state: DownloadState, file: StaticString = #file, line: UInt = #line) {
        XCTAssertDownloadState(target.getDownloadState(track), state, file: file, line: line)
    }

    func testNotDownloading() {
        let track = TrackStub()
        _ = track.addRecord(fileSize: 1230, serverId: .MdsOnlineRu, partNumber: 0)
        _ = track.addRecord(fileSize: 1231, serverId: .ArchiveOrg2015, partNumber: 0)

        assertState(ofTrack: track, .notDownloaded)
    }

    func testDownloadInProgress() {
        let track = TrackStub()
        let recordId1 = track.addRecord(fileSize: 1230, serverId: .MdsOnlineRu, partNumber: 0)
        _ = track.addRecord(fileSize: 1231, serverId: .ArchiveOrg2015, partNumber: 0)

        updateState(ofRecord: recordId1, .caching(getProgress(10, 20)))
        assertState(ofTrack: track, .downloading(.MdsOnlineRu, getProgress(1, 2)))
    }

    func testDownloaded() {
        let track = TrackStub()
        let recordId1 = track.addRecord(fileSize: 1230, serverId: .MdsOnlineRu, partNumber: 0)
        _ = track.addRecord(fileSize: 1231, serverId: .ArchiveOrg2015, partNumber: 0)

        updateState(ofRecord: recordId1, .cached(URL(fileURLWithPath: "/file1.mp3"), 1230))
        assertState(ofTrack: track, .downloaded(.MdsOnlineRu, 1230))
    }

    func testMultiFileDownloadInProgress() {
        let track = TrackStub()
        let recordId1 = track.addRecord(fileSize: 250, serverId: .MdsOnlineRu, partNumber: 1)
        let recordId2 = track.addRecord(fileSize: 750, serverId: .MdsOnlineRu, partNumber: 2)
        _ = track.addRecord(fileSize: 1231, serverId: .ArchiveOrg2015, partNumber: 0)

        updateState(ofRecord: recordId1, .caching(getProgress(5, 10)))
        updateState(ofRecord: recordId2, .caching(getProgress(10, 20)))
        assertState(ofTrack: track, .downloading(.MdsOnlineRu, getProgress(1, 2)))
    }

    func testMultiFileDownloaded() {
        let track = TrackStub()
        let recordId1 = track.addRecord(fileSize: 250, serverId: .MdsOnlineRu, partNumber: 1)
        let recordId2 = track.addRecord(fileSize: 750, serverId: .MdsOnlineRu, partNumber: 2)
        _ = track.addRecord(fileSize: 1231, serverId: .ArchiveOrg2015, partNumber: 0)

        updateState(ofRecord: recordId1, .cached(URL(fileURLWithPath: "/file1.mp3"), 250))
        updateState(ofRecord: recordId2, .cached(URL(fileURLWithPath: "/file2.mp3"), 750))
        assertState(ofTrack: track, .downloaded(.MdsOnlineRu, 1000))
    }

    func testPartlyDownloaded() {
        let track = TrackStub()
        let recordId1 = track.addRecord(fileSize: 250, serverId: .MdsOnlineRu, partNumber: 1)
        _ = track.addRecord(fileSize: 750, serverId: .MdsOnlineRu, partNumber: 2)
        _ = track.addRecord(fileSize: 1231, serverId: .ArchiveOrg2015, partNumber: 0)

        updateState(ofRecord: recordId1, .cached(URL(fileURLWithPath: "/file1.mp3"), 250))
        assertState(ofTrack: track, .incomplete(.MdsOnlineRu, getProgress(1, 4)))
    }

    func testPartlyDownloadInProgress() {
        let track = TrackStub()
        let recordId1 = track.addRecord(fileSize: 250, serverId: .MdsOnlineRu, partNumber: 1)
        let recordId2 = track.addRecord(fileSize: 750, serverId: .MdsOnlineRu, partNumber: 2)
        _ = track.addRecord(fileSize: 1231, serverId: .ArchiveOrg2015, partNumber: 0)

        updateState(ofRecord: recordId1, .cached(URL(fileURLWithPath: "/file1.mp3"), 250))
        updateState(ofRecord: recordId2, .caching(getProgress(10, 30)))
        assertState(ofTrack: track, .downloading(.MdsOnlineRu, getProgress(1, 2)))
    }

    func testCorruptedDownloadInProgress() {
        let track = TrackStub()
        let recordId1 = track.addRecord(fileSize: 250, serverId: .MdsOnlineRu, partNumber: 1)
        let recordId2 = track.addRecord(fileSize: 750, serverId: .MdsOnlineRu, partNumber: 2)
        let recordId3 = track.addRecord(fileSize: 1231, serverId: .ArchiveOrg2015, partNumber: 3)

        updateState(ofRecord: recordId1, .cached(URL(fileURLWithPath: "/file1.mp3"), 250))
        updateState(ofRecord: recordId2, .caching(getProgress(10, 30)))
        updateState(ofRecord: recordId3, .caching(getProgress(20, 30)))
        assertState(ofTrack: track, .corrupted(250))
    }

    func testCorruptedDownload() {
        let track = TrackStub()
        let recordId1 = track.addRecord(fileSize: 250, serverId: .MdsOnlineRu, partNumber: 1)
        let recordId2 = track.addRecord(fileSize: 750, serverId: .MdsOnlineRu, partNumber: 2)
        let recordId3 = track.addRecord(fileSize: 1231, serverId: .ArchiveOrg2015, partNumber: 0)

        updateState(ofRecord: recordId1, .cached(URL(fileURLWithPath: "/file1.mp3"), 250))
        updateState(ofRecord: recordId2, .caching(getProgress(10, 30)))
        updateState(ofRecord: recordId3, .cached(URL(fileURLWithPath: "/file3.mp3"), 1231))
        assertState(ofTrack: track, .corrupted(250 + 1231))
    }

    func testWorkflow() {
        let track = TrackStub()
        let recordId0 = track.addRecord(fileSize: 2460, serverId: .ArchiveOrg2015, partNumber: 0)
        let recordId1 = track.addRecord(fileSize: 1230, serverId: .MdsOnlineRu, partNumber: 0) // 1/4 of the track
        let recordId2 = track.addRecord(fileSize: 3690, serverId: .MdsOnlineRu, partNumber: 1) // 3/4 of the track

        // one of the records starts downloading
        updateState(ofRecord: recordId1, .caching(getProgress(10, 20)))
        assertState(ofTrack: track, .downloading(.MdsOnlineRu, getProgress(1, 8))) // half of 1/4

        // and the second one
        updateState(ofRecord: recordId2, .caching(getProgress(10, 20)))
        assertState(ofTrack: track, .downloading(.MdsOnlineRu, getProgress(1, 2))) // two halves together

        // then one finishes
        updateState(ofRecord: recordId1, .cached(URL(fileURLWithPath: "/file1.mp3"), 5432)) // note the totally different file size - it shouldn't affect progress
        assertState(ofTrack: track, .downloading(.MdsOnlineRu, getProgress(5, 8))) // 1/4 + half of 3/4

        // and the second one too
        updateState(ofRecord: recordId2, .cached(URL(fileURLWithPath: "/file2.mp3"), 4000))
        assertState(ofTrack: track, .downloaded(.MdsOnlineRu, 4000+5432))

        // then one is deleted
        updateState(ofRecord: recordId1, .notCached)
        assertState(ofTrack: track, .incomplete(.MdsOnlineRu, getProgress(3, 4)))

        // then the wrong one starts downloading
        updateState(ofRecord: recordId0, .caching(getProgress(10, 20)))
        assertState(ofTrack: track, .corrupted(4000))

        // then the wrong one finishes
        updateState(ofRecord: recordId0, .cached(URL(fileURLWithPath: "/file0.mp3"), 18))
        assertState(ofTrack: track, .corrupted(4000+18))

        // then one record is deleted
        updateState(ofRecord: recordId2, .notCached)
        assertState(ofTrack: track, .downloaded(.ArchiveOrg2015, 18))

        // then the only record falls back to downloading somehow
        updateState(ofRecord: recordId0, .caching(getProgress(10, 20)))
        assertState(ofTrack: track, .downloading(.ArchiveOrg2015, getProgress(1, 2)))

        // and the last one is deleted too
        updateState(ofRecord: recordId0, .notCached)
        assertState(ofTrack: track, .notDownloaded)
    }

    func testProgressChange() {
        let track = TrackStub()
        _ = track.addRecord(fileSize: 2460, serverId: .ArchiveOrg2015, partNumber: 0)
        let recordId1 = track.addRecord(fileSize: 1230, serverId: .MdsOnlineRu, partNumber: 0) // 1/4 of the track
        let recordId2 = track.addRecord(fileSize: 3690, serverId: .MdsOnlineRu, partNumber: 1) // 3/4 of the track

        updateState(ofRecord: recordId2, .caching(getProgress(10, 20)))
        assertState(ofTrack: track, .downloading(.MdsOnlineRu, getProgress(3, 8))) // half of 3/4

        let p1 = getProgress(5, 20)
        updateState(ofRecord: recordId1, .caching(p1))
        assertState(ofTrack: track, .downloading(.MdsOnlineRu, getProgress(7, 16))) // half of 3/4 + quarter of 1/4

        p1.completedUnitCount = 10
        assertState(ofTrack: track, .downloading(.MdsOnlineRu, getProgress(1, 2))) // two halves

        p1.completedUnitCount = 20
        assertState(ofTrack: track, .downloading(.MdsOnlineRu, getProgress(5, 8))) // half of 3/4 + 1/4

        updateState(ofRecord: recordId1, .notCached)
        assertState(ofTrack: track, .downloading(.MdsOnlineRu, getProgress(3, 8))) // half of 3/4

        updateState(ofRecord: recordId1, .caching(getProgress(10, 20)))
        assertState(ofTrack: track, .downloading(.MdsOnlineRu, getProgress(1, 2))) // two halves
    }

    func testCorruptedUncorruptedTransitions() {
        let track = TrackStub()
        let recordId0 = track.addRecord(fileSize: 2460, serverId: .ArchiveOrg2015, partNumber: 0)
        let recordId1 = track.addRecord(fileSize: 1230, serverId: .MdsOnlineRu, partNumber: 0)
        _ = track.addRecord(fileSize: 3690, serverId: .MdsOnlineRu, partNumber: 1)

        let p1 = getProgress(10, 20)
        updateState(ofRecord: recordId0, .caching(p1))
        assertState(ofTrack: track, .downloading(.ArchiveOrg2015, getProgress(1, 2)))

        let p2 = getProgress(10, 20)
        updateState(ofRecord: recordId1, .caching(p2))
        assertState(ofTrack: track, .corrupted(0))

        p1.completedUnitCount = 15
        assertState(ofTrack: track, .corrupted(0))

        updateState(ofRecord: recordId1, .notCached)
        assertState(ofTrack: track, .downloading(.ArchiveOrg2015, getProgress(3, 4)))
    }

    func testDoubleUpdates() {
        let track = TrackStub()
        let recordId = track.addRecord(fileSize: 1234, serverId: .MdsOnlineRu, partNumber: 0)

        updateState(ofRecord: recordId, .notCached)
        assertState(ofTrack: track, .notDownloaded)

        updateState(ofRecord: recordId, .notCached)
        assertState(ofTrack: track, .notDownloaded)

        let p = getProgress(10, 20)
        updateState(ofRecord: recordId, .caching(p))
        assertState(ofTrack: track, .downloading(.MdsOnlineRu, getProgress(1, 2)))

        updateState(ofRecord: recordId, .caching(p))
        assertState(ofTrack: track, .downloading(.MdsOnlineRu, getProgress(1, 2)))

        updateState(ofRecord: recordId, .cached(URL(fileURLWithPath: "/file2.mp3"), 1234))
        assertState(ofTrack: track, .downloaded(.MdsOnlineRu, 1234))


        updateState(ofRecord: recordId, .cached(URL(fileURLWithPath: "/file2.mp3"), 1234))
        assertState(ofTrack: track, .downloaded(.MdsOnlineRu, 1234))
    }
}
