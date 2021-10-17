import Foundation
@testable import Mds

class DataReaderDummy: DataReader {
    func getAllTracks() -> [MdsTrack] {
        return []
    }

    func getTotalTrackCount() -> Int {
        return 0
    }

    func getUnfinishedTracks() -> [MdsTrack] {
        return []
    }

    func getAllTrackListenInfos() -> [MdsTrackListenInfo] {
        return []
    }

    func getLastTrack() -> (MdsTrack, ServerId)? {
        return nil
    }

    func tryGetRecord(withUrl url: URL) -> MdsRecord? {
        return nil
    }

    func tryGetTrackListenInfo(forTrack trackId: TrackId) -> MdsTrackListenInfo? {
        return nil
    }

    func tryGetTrack(withId id: TrackId) -> MdsTrack? {
        return nil
    }

    func tryGetRecord(withId id: RecordId) -> MdsRecord? {
        return nil
    }
}
