import Foundation

enum ServerId: Int16 {
    case MdsOnlineRu = 0
    case KallistoRu = 1
    case MdsClubRu = 2
    case ArchiveOrg2015 = 3
    case ArchiveOrg2018 = 4

    var next: ServerId? { return ServerId(rawValue: rawValue + 1) }
}

protocol MdsRecord {
    var durationInSeconds: Int32 { get }
    var fileSize: Int64 { get }
    var partNumber: Int32 { get }
    var recordId: RecordId { get }
    var server: ServerId { get }
    var url: URL { get }
    var mdsTrack: MdsTrack? { get }
}
