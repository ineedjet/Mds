import Foundation

extension MdsTrackMO {
    var fullyListened: Bool { DataStorage.reader.tryGetTrackListenInfo(forTrack: self.trackId)?.fullyListened ?? false }
    var lastListened: Date? { DataStorage.reader.tryGetTrackListenInfo(forTrack: self.trackId)?.lastListened }
    var lastPosition: Double { DataStorage.reader.tryGetTrackListenInfo(forTrack: self.trackId)?.lastPosition ?? 0.0 }
    var lastServerId: ServerId? {
        guard let listenInfo = DataStorage.reader.tryGetTrackListenInfo(forTrack: self.trackId) else {
            return nil
        }
        return ServerId(rawValue: listenInfo.lastServerId)
    }
}
