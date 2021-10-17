import Foundation

fileprivate let SortingKey = "sortingMode"
fileprivate let BackUpDownloadsKey = "backUpDownloads"
fileprivate let HideFullyListenedKey = "hideFullyListened"

enum SortingMode: Int {
    case author
    case date
    case station
    case durationAsc
    case durationDesc
}

extension UserDefaults {
    /** Key-Value Observable version of `sortingMode` */
    @objc var rawSortingMode: Int {
        get { return integer(forKey: SortingKey) }
        set { set(newValue, forKey: SortingKey) }
    }
    @objc var backUpDownloads: Bool {
        get { return bool(forKey: BackUpDownloadsKey) }
        set { set(newValue, forKey: BackUpDownloadsKey) }
    }
    @objc var hideFullyListened: Bool {
        get { return bool(forKey: HideFullyListenedKey) }
        set { set(newValue, forKey: HideFullyListenedKey) }
    }
    var sortingMode: SortingMode {
        get { return SortingMode(rawValue: rawSortingMode) ?? .author }
        set { rawSortingMode = newValue.rawValue }
    }
}
