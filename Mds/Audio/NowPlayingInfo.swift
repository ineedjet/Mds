import MediaPlayer

private func getArtwork(size: CGSize) -> UIImage {
    UIGraphicsBeginImageContext(size)
    defer { UIGraphicsEndImageContext() }
    #imageLiteral(resourceName: "big-logo.jpg").draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    return UIGraphicsGetImageFromCurrentImageContext()!
}

final class NowPlayingInfo {
    static let shared = NowPlayingInfo()
    private var currentInfo: [String : Any]?
    private init() {
        currentInfo = nil
    }

    private func provideInfo(_ info: [String : Any]?) {
        guard let info = info else {
            currentInfo = nil
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        currentInfo = currentInfo ?? [:]
        for (k,v) in info {
            currentInfo?[k] = v
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = currentInfo
    }

    func reset() {
        provideInfo(nil)
        if #available(iOS 13.0, *) {
            MPNowPlayingInfoCenter.default().playbackState = .stopped
        }
    }

    func update(track: MdsTrack) {
        var nowPlayingInfo: [String:Any] = [
            MPMediaItemPropertyTitle: track.trackTitle,
            MPMediaItemPropertyArtist: track.trackAuthor,
            MPMediaItemPropertyAlbumTitle: "Модель для сборки",
            MPMediaItemPropertyArtwork: MPMediaItemArtwork(boundsSize: #imageLiteral(resourceName: "big-logo.jpg").size) { size in getArtwork(size: size)},
            MPNowPlayingInfoPropertyPlaybackRate: NSNumber(value: 0.0), // item is paused
        ]
        if let date = track.date {
            nowPlayingInfo[MPMediaItemPropertyReleaseDate] = date
        }
        provideInfo(nowPlayingInfo)
        if #available(iOS 13.0, *) {
            MPNowPlayingInfoCenter.default().playbackState = .unknown
        }
    }

    func update(duration: TimeInterval) {
        provideInfo([MPMediaItemPropertyPlaybackDuration: NSNumber(value: duration)])
    }

    func update(time: TimeInterval, playing: Bool, displayAsPlaying: Bool? = nil) {
        provideInfo([
            MPNowPlayingInfoPropertyElapsedPlaybackTime: NSNumber(value: time),
            MPNowPlayingInfoPropertyPlaybackRate: NSNumber(value: playing ? 1.0 : 0.0)
        ])
        if #available(iOS 13.0, *) {
            MPNowPlayingInfoCenter.default().playbackState = displayAsPlaying ?? playing ? .playing : .paused
        }
    }
}
