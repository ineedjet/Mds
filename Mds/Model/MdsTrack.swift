import Foundation

protocol MdsTrack: AnyObject {
    var trackAuthor: String { get }
    var date: Date? { get }
    var durationInMinutes: Int32 { get }
    var longDesc: String? { get }
    var station: String? { get }
    var trackTitle: String { get }
    var trackId: TrackId { get }
    var fullyListened: Bool { get }
    var lastListened: Date? { get }
    var lastPosition: Double { get }
    var lastServerId: ServerId? { get }

    var allRecords: [MdsRecord] { get }
    func getRecords(_ server: ServerId) -> [MdsRecord]
    func getServersWithSizes() -> [(ServerId, Int64)]
}

func ==(lhs: MdsTrack, rhs: MdsTrack) -> Bool {
    return lhs.trackId == rhs.trackId
}
