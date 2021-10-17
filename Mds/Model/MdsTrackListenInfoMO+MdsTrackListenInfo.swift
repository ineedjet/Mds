extension MdsTrackListenInfoMO: MdsTrackListenInfo {
    var track: MdsTrack? { DataStorage.reader.tryGetTrack(withId: self.trackId) }
}
