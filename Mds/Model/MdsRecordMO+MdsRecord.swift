import Foundation

extension MdsRecordMO: MdsRecord {
    var mdsTrack: MdsTrack? { self.track }
    var url: URL {
        get {
            guard let urlString = urlString, let url = URL(string: urlString) else {
                fatalError("Invalid url for record \(self.recordId)")
            }
            return url
        }
        set {
            urlString = newValue.absoluteString
        }
    }
    var server: ServerId {
        get {
            return ServerId(rawValue: serverId) ?? .MdsOnlineRu
        }
        set {
            serverId = newValue.rawValue
        }
    }
}
