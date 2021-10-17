import Foundation

protocol DataWriter {
    func set(lastListened: Date, forTrack track: MdsTrack)
    func set(lastPosition: Double, forTrack track: MdsTrack)
    func set(lastPosition: Double, lastServerId: ServerId, forTrack track: MdsTrack)
    func set(fullyListened: Bool, forTrack track: MdsTrack)
}
