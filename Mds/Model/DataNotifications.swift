import Foundation

let DataStorageTrackKey: String = "track"
let DataStoragePropertiesKey: String = "properties"

extension Notification.Name {
    static let dataStorageDidUpdateTrack = Notification.Name(rawValue: "DataStorageDidUpdateTrack")
}

struct DataStorageTrackProperties: OptionSet {
    let rawValue: Int

    static let lastListened = DataStorageTrackProperties(rawValue: 1 << 0)
    static let lastPosition = DataStorageTrackProperties(rawValue: 1 << 1)
    static let lastServerId = DataStorageTrackProperties(rawValue: 1 << 2)
    static let fullyListened = DataStorageTrackProperties(rawValue: 1 << 3)
}
