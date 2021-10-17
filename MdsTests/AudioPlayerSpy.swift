import XCTest
@testable import Mds

class AudioPlayerSpy: AudioPlayer {
    var state: AudioPlayerState = .idle {
        didSet {
            NotificationCenter.default.post(name: .audioPlayerDidChangeState, object: self,
                                            userInfo: [AudioPlayerPreviousStateKey : oldValue])
        }
    }
    var position: TimeInterval = 0
    var duration: TimeInterval = 0
    var sleepTimer: TimeInterval?

    private(set) var prepareRequests: [MdsTrack] = []
    func prepare(_ track: MdsTrack) {
        prepareRequests.append(track)
    }

    func cancelPreparation(ofTrack track: MdsTrack, becauseOf error: Error?) {
        prepareRequests = prepareRequests.filter{$0.trackId != track.trackId}
        if let error = error {
            state = .error(error)
        }
        else {
            state = .idle
        }
    }

    private(set) var loadRequests: [(MdsTrack,ServerId)] = []
    func load(_ track: MdsTrack, fromServer server: ServerId) {
        loadRequests.append((track, server))
    }

    private(set) var playRequests = 0
    func play() {
        playRequests += 1
    }

    private(set) var pauseRequests = 0
    func pause() {
        pauseRequests += 1
    }

    private(set) var stopRequests = 0
    func stop() {
        stopRequests += 1
    }

    func select(_ track: MdsTrack, onServer serverId: ServerId) {
        fatalError("select is not supported")
    }

    private(set) var setPositionRequests: [TimeInterval] = []
    func setPosition(_ time: TimeInterval) {
        setPositionRequests.append(time)
    }

    private(set) var skipRequests: [TimeInterval] = []
    func skip(_ interval: TimeInterval) {
        skipRequests.append(interval)
    }
}
