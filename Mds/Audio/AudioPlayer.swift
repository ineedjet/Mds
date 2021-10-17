import Foundation

enum AudioPlayerState {
    case idle
    case error(Error)
    case selected(MdsTrack, ServerId)
    case preparing(MdsTrack)
    case loading(MdsTrack)
    case playing(MdsTrack)
    case paused(MdsTrack)
}

let AudioPlayerPreviousStateKey: String = "AudioPlayerPreviousState"

extension Notification.Name {
    static let audioPlayerDidChangeState = Notification.Name(rawValue: "AudioPlayerDidChangeState")
    static let audioPlayerDidUpdatePosition = Notification.Name(rawValue: "AudioPlayerDidUpdatePosition")
    static let audioPlayerDidUpdateDuration = Notification.Name(rawValue: "AudioPlayerDidUpdateDuration")
    static let audioPlayerDidUpdateSleepTimer = Notification.Name(rawValue: "AudioPlayerDidUpdateSleepTimer")
}

protocol AudioPlayer: AnyObject {
    var state: AudioPlayerState { get }

    var position: TimeInterval { get }
    var duration: TimeInterval { get }
    var sleepTimer: TimeInterval? { get set }

    func prepare(_ track: MdsTrack)
    func cancelPreparation(ofTrack track: MdsTrack, becauseOf error: Error?)
    func select(_ track: MdsTrack, onServer serverId: ServerId)
    func load(_ track: MdsTrack, fromServer server: ServerId)

    func play()
    func pause()
    func stop()
    func setPosition(_ time: TimeInterval)
    func skip(_ interval: TimeInterval)
}

extension AudioPlayer {
    func cancelPreparation(ofTrack track: MdsTrack) {
        self.cancelPreparation(ofTrack: track, becauseOf: nil)
    }
}
