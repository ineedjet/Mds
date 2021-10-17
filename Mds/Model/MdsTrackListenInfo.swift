import Foundation

protocol MdsTrackListenInfo {
    var track: MdsTrack? { get }
    var fullyListened: Bool { get }
    var lastListened: Date? { get }
    var lastPosition: Double { get }
    var lastServerId: Int16 { get }
}
