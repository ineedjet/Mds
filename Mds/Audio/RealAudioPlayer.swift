import AVKit

/** Frequency of saving current position to the database */
fileprivate let PlaybackTimerResolutionSeconds: Double = 5.0
/** Frequency of reporting current position to the UI */
fileprivate let PlaybackPositionUpdateFrequencySeconds: Double = 0.25
/** Duration of the track that is guaranteed to be repeated when restoring previous position */
fileprivate let MinCrossfadeDurationSeconds: Double = 5.0

fileprivate func findRecord(in records:[MdsRecord], atTime time: TimeInterval) -> (Int, TimeInterval)? {
    guard time >= 0 else {
        return nil
    }
    var totalTime: TimeInterval = 0
    for i in 0..<records.count {
        let newTotal = totalTime + TimeInterval(records[i].durationInSeconds)
        if time < newTotal {
            return (i, time - totalTime)
        }
        totalTime = newTotal
    }
    return nil
}

final class RealAudioPlayer: NSObject, AudioPlayer {
    static let shared: AudioPlayer = RealAudioPlayer()
    private var cmdCenter: RemoteCommandCenter!
    private var allRecords: [MdsRecord] = []
    private var didPlayToCompletion: Bool = false
    private var playerItemStatusObservations: [NSKeyValueObservation] = []
    private var currentRecord: Int = 0 {
        didSet {
            currentRecordStart = TimeInterval(allRecords.prefix(currentRecord).reduce(0) { $0 + $1.durationInSeconds })
        }
    }
    private var currentRecordStart: TimeInterval = 0
    private var player: AVQueuePlayer?
    private var playerStatusObservation: NSKeyValueObservation?
    private var playerTimeControlStatusObservation: NSKeyValueObservation?
    private var playerSlowTimeObserverToken: Any?
    private var playerFastTimeObserverToken: Any?
    private(set) var state: AudioPlayerState = .idle {
        didSet {
            NotificationCenter.default.post(name: .audioPlayerDidChangeState, object: self,
                                            userInfo: [AudioPlayerPreviousStateKey : oldValue])
        }
    }

    private var updatePosition: Bool = true
    private(set) var position: TimeInterval = 0 {
        didSet {
            NotificationCenter.default.post(name: .audioPlayerDidUpdatePosition, object: self)
        }
    }

    private(set) var duration: TimeInterval = 0 {
        didSet {
            NotificationCenter.default.post(name: .audioPlayerDidUpdateDuration, object: self)
        }
    }

    var sleepTimer: TimeInterval? {
        didSet {
            NotificationCenter.default.post(name: .audioPlayerDidUpdateSleepTimer, object: self)
        }
    }

    private override init() {
        super.init()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)

        cmdCenter = RemoteCommandCenter(for: self)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDonePlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadManagerDidUpdateCache), name: .downloadManagerDidUpdateCache, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func pause() {
        if case .playing = state, let player = player {
            player.pause()
        }
    }

    func play() {
        if case .paused = state, let player = player {
            player.play()
        }
        if case .selected(let track, let serverId) = state {
            load(track, fromServer: serverId)
        }
    }

    func select(_ track: MdsTrack, onServer serverId: ServerId) {
        if case .idle = state {
            state = .selected(track, serverId)
            NowPlayingInfo.shared.update(track: track)
        }
    }

    private func getAccuratePosition(of player: AVPlayer) -> TimeInterval {
        return currentRecordStart + player.currentTime().seconds
    }

    func setPosition(_ time: TimeInterval) {
        guard let player = player else {
            return
        }
        let time = max(time, 0) // for the case time < 0
        guard let (targetRecord, timeWithinRecord) = findRecord(in: allRecords, atTime: time) else {
            // for the case time > duration
            stop()
            return
        }
        let isPlaying: Bool
        switch state {
        case .playing:
            isPlaying = true
        case .paused:
            isPlaying = false
        default:
            print("Attempt to set position when neither playing nor paused")
            return
        }
        guard targetRecord == currentRecord else {
            self.updatePosition = false
            NowPlayingInfo.shared.update(time: time, playing: false, displayAsPlaying: isPlaying)
            load(records: allRecords, position: time, toleranceBefore: .zero, startPlaying: isPlaying)
            return
        }
        self.updatePosition = false
        self.position = time
        NowPlayingInfo.shared.update(time: time, playing: false, displayAsPlaying: isPlaying)
        player.seek(to: CMTime(seconds: timeWithinRecord, preferredTimescale: 1000), toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] success in
            guard let strongSelf = self else {
                return
            }
            strongSelf.updatePosition = true
            if success {
                NowPlayingInfo.shared.update(time: strongSelf.getAccuratePosition(of: player), playing: player.timeControlStatus == .playing ? true : false)
            }
        }
    }

    func skip(_ interval: TimeInterval) {
        if let player = player {
            setPosition(getAccuratePosition(of: player) + interval)
        }
    }

    @objc private func playerDonePlaying() {
        if currentRecord < allRecords.count - 1 {
            currentRecord += 1
        }
        else {
            stop()
        }
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        if type == .began {
            pause()
        }
        else if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    play()
                }
            }
        }
    }

    func stop() {
        stop(nil)
    }

    private func stop(_ error: Error?) {
        if didPlayToCompletion {
            switch state {
            case .playing(let track), .paused(let track):
                DataStorage.writer.set(fullyListened: true, forTrack: track)
            case .selected, .preparing, .loading, .idle, .error:
                break
            }
        }
        destroyPlayer()
        resetState(becauseOf: error)
    }

    private func destroyPlayer() {
        if let player = player, let playerTimeObserverToken = playerSlowTimeObserverToken {
            player.removeTimeObserver(playerTimeObserverToken)
        }
        if let player = player, let playerTimeObserverToken = playerFastTimeObserverToken {
            player.removeTimeObserver(playerTimeObserverToken)
        }
        playerSlowTimeObserverToken = nil
        playerFastTimeObserverToken = nil
        playerTimeControlStatusObservation = nil
        playerItemStatusObservations = []
        playerStatusObservation = nil
        sleepTimer = nil
        player = nil
        didPlayToCompletion = false
        allRecords = []
        currentRecord = 0
        updatePosition = false
    }

    private func resetState(becauseOf error: Error? = nil) {
        if let error = error {
            state = .error(error)
        }
        else {
            state = .idle
        }
        NowPlayingInfo.shared.reset()
    }

    private func createPlayerItem(from record: MdsRecord, callbackWhenReady: ((AVPlayerItem) -> Void)?) -> AVPlayerItem {
        // asset
        let url = DownloadManager.shared.getCachedUrl(ofRecord: record) ?? record.url
        let asset = AVAsset(url: url)

        // player item
        let assetKeys = [
            "playable",
            "hasProtectedContent",
            ]
        let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: assetKeys)
        let statusObservation = playerItem.observe(\.status) { (_, change) in
            DispatchQueue.main.async {
                guard playerItem.status != .failed else {
                    print("Failed to play item \(playerItem.error?.localizedDescription ?? "")")
                    self.stop(playerItem.error)
                    return
                }
                callbackWhenReady?(playerItem)
            }
        }
        playerItemStatusObservations.append(statusObservation)
        return playerItem
    }

    func prepare(_ track: MdsTrack) {
        stop()
        state = .preparing(track)
    }

    func cancelPreparation(ofTrack track: MdsTrack, becauseOf error: Error? = nil) {
        if case let .preparing(t) = state, t.trackId == track.trackId {
            resetState(becauseOf: error)
        }
    }

    func load(_ track: MdsTrack, fromServer server: ServerId) {
        let records = track.getRecords(server)
        let position = track.lastServerId == server
            ? max(track.lastPosition-MinCrossfadeDurationSeconds, 0)
            : 0
        resetState()
        state = .loading(track)
        NowPlayingInfo.shared.update(track: track)
        return load(records: records, position: position, toleranceBefore: .positiveInfinity, startPlaying: true)
    }

    private func load(records: [MdsRecord], position: TimeInterval, toleranceBefore: CMTime, startPlaying: Bool) {
        destroyPlayer()
        guard records.count > 0 else {
            return
        }

        guard let (startItem, time) = findRecord(in: records, atTime: position) else {
            return
        }

        // defer
        var readyCallbackExecuted = false
        var playerItems: [AVPlayerItem] = []
        playerItems.append(createPlayerItem(from: records[startItem]) { (playerItem: AVPlayerItem) in
            guard !readyCallbackExecuted,
                let player = self.player,
                player.status == .readyToPlay,
                playerItem.status == .readyToPlay
                else {
                    return
            }
            readyCallbackExecuted = true
            let pos = CMTime(seconds: time, preferredTimescale: 1000)
            player.seek(to: pos, toleranceBefore: toleranceBefore, toleranceAfter: .zero) { success in
                guard success else {
                    return
                }
                self.updatePosition = true
                if startPlaying {
                    player.play()
                }
                else {
                    NowPlayingInfo.shared.update(time: self.getAccuratePosition(of: player), playing: false)
                }
            }
        })
        for record in records.suffix(from: startItem + 1) {
            playerItems.append(createPlayerItem(from: record, callbackWhenReady: nil))
        }

        // player
        let player = AVQueuePlayer(items: playerItems)
        self.playerStatusObservation = player.observe(\.status) { (_, change) in
            DispatchQueue.main.async {
                guard player.status != .failed else {
                    print("Failed to play \(player.error?.localizedDescription ?? "")")
                    self.stop(player.error)
                    return
                }
            }
        }
        self.playerTimeControlStatusObservation = player.observe(\.timeControlStatus) { (_, change) in
            DispatchQueue.main.async {
                self.playerDidChangeTimeControlStatus(player)
            }
        }
        self.playerSlowTimeObserverToken = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: PlaybackTimerResolutionSeconds, preferredTimescale: 1000),
            queue: DispatchQueue.main) { [weak self] _ in
                guard let self = self, case .playing(let track) = self.state else {
                    return
                }
                if self.position + PlaybackTimerResolutionSeconds > self.duration {
                    DataStorage.writer.set(lastPosition: 0, forTrack: track)
                    self.didPlayToCompletion = true
                }
                else {
                    DataStorage.writer.set(lastPosition: self.position, forTrack: track)
                }
        }
        self.playerFastTimeObserverToken = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: PlaybackPositionUpdateFrequencySeconds, preferredTimescale: 1000),
            queue: DispatchQueue.main) { [weak self] time in
                if let self = self {
                    if self.updatePosition {
                        self.position = self.currentRecordStart + time.seconds
                    }
                    // TODO: Optimize
                    if let sleepTimer = self.sleepTimer {
                        self.sleepTimer = sleepTimer - PlaybackPositionUpdateFrequencySeconds
                        if sleepTimer <= 0 {
                            self.pause()
                            self.sleepTimer = nil
                        }
                    }
                }
        }
        self.player = player

        // rest
        self.position = position
        self.allRecords = records
        self.currentRecord = startItem
        let duration = Double(records.reduce(0) { $0 + $1.durationInSeconds })
        self.duration = duration
        NowPlayingInfo.shared.update(duration: duration)
    }

    private func playerDidChangeTimeControlStatus(_ player: AVPlayer) {
        switch player.timeControlStatus {
        case .playing:
            if case let .loading(track) = state {
                state = .playing(track)
            }
            else if case let .paused(track) = state {
                state = .playing(track)
            }
            if self.updatePosition {
                NowPlayingInfo.shared.update(time: getAccuratePosition(of: player), playing: true)
            }
        case .paused:
            if case let .playing(track) = state {
                state = .paused(track)
            }
            if self.updatePosition {
                NowPlayingInfo.shared.update(time: getAccuratePosition(of: player), playing: false)
            }
        case .waitingToPlayAtSpecifiedRate:
            if self.updatePosition {
                NowPlayingInfo.shared.update(time: getAccuratePosition(of: player), playing: false, displayAsPlaying: true)
            }
        @unknown default:
            fatalError("Unknown player status: \(player.timeControlStatus)")
        }
    }

    @objc private func downloadManagerDidUpdateCache(_ notification: NSNotification) {
        guard let updatedTrack = notification.userInfo?[DownloadManagerTrackKey] as? MdsTrack else {
            print("Cache is updated, but the track information is missing")
            return
        }
        let track: MdsTrack
        let startPlaying: Bool
        switch state {
        case .playing(let t), .loading(let t):
            track = t
            startPlaying = true
        case .paused(let t):
            track = t
            startPlaying = false
        default:
            return
        }

        guard track.trackId == updatedTrack.trackId, let player = player else {
            return
        }

        let allPlayerItems = player.items()
        let commonCount = min(allPlayerItems.count, allRecords.count)

        let records = Array(allRecords.suffix(commonCount))
        let playerItems = Array(allPlayerItems.suffix(commonCount))
        assert(playerItems.count == commonCount)
        assert(records.count == commonCount)

        for i in 0..<commonCount {
            if let cachedUrl = DownloadManager.shared.getCachedUrl(ofRecord: records[i]),
                let currentUrl = (playerItems[i].asset as? AVURLAsset)?.url,
                currentUrl != cachedUrl {
                // restart playback from cache
                load(records: records, position: getAccuratePosition(of: player), toleranceBefore: .zero, startPlaying: startPlaying)
            }
        }
    }
}
