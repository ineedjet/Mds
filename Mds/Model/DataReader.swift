import Foundation

protocol DataReader {
    func getAllTracks() -> [MdsTrack]
    func getTotalTrackCount() -> Int
    func getUnfinishedTracks()  -> [MdsTrack]
    func getAllTrackListenInfos() -> [MdsTrackListenInfo]
    func getLastTrack() -> (MdsTrack, ServerId)?

    func tryGetRecord(withId id: RecordId) -> MdsRecord?
    func tryGetRecord(withUrl url: URL) -> MdsRecord?
    func tryGetTrack(withId id: TrackId) -> MdsTrack?
    func tryGetTrackListenInfo(forTrack trackId: TrackId) -> MdsTrackListenInfo?
}
