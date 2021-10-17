import Foundation
@testable import Mds

struct RecordStub: MdsRecord {
    private static var stubCount: Int32 = 156
    let recordId: RecordId = {
        RecordStub.stubCount += 1
        return RecordStub.stubCount
    }()

    let durationInSeconds: Int32 = 0
    let fileSize: Int64
    let server: ServerId
    let partNumber: Int32
    let url: URL
    let mdsTrack: MdsTrack?
}

fileprivate(set) var trackCache: [TrackId: MdsTrack] = [:]
fileprivate(set) var recordCache: [RecordId: MdsRecord] = [:]
func clearCaches() {
    trackCache = [:]
    recordCache = [:]
}

class TrackStub: MdsTrack {
    private static var stubCount: Int32 = 95
    let trackId: TrackId

    init() {
        TrackStub.stubCount += 1
        trackId = TrackStub.stubCount
        trackCache[TrackStub.stubCount] = self
    }

    func addRecord(fileSize: Int64, serverId: ServerId, partNumber: Int32, url: URL = URL(string: "http://example.com/")!) -> RecordId {
        let stub = RecordStub(fileSize: fileSize, server: serverId, partNumber: partNumber, url: url, mdsTrack: self)
        allRecords.append(stub)
        recordCache[stub.recordId] = stub
        return stub.recordId
    }

    let trackAuthor: String = "Stub author"
    let date: Date? = nil
    let durationInMinutes: Int32 = 0
    let longDesc: String? = nil
    let station: String? = nil
    let trackTitle: String = "Stub title"
    let fullyListened: Bool = false
    let lastListened: Date? = nil
    let lastPosition: Double = 0
    let lastServerId: ServerId? = nil

    private(set) var allRecords: [MdsRecord] = []
}

func getProgress(_ done: Int64, _ total: Int64) -> Progress {
    let progress = Progress(totalUnitCount: total)
    progress.completedUnitCount = done
    return progress
}
