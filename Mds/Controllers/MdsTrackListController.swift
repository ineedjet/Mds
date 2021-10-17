import Foundation

fileprivate extension Date {
    var yearString: String {
        return "\(Calendar.current.component(.year, from: self))"
    }
}

extension MdsTrack {
    var durationGroup: String {
        if durationInMinutes >= 90 {
            return "Длинее полутора часов"
        }
        if durationInMinutes < 10 {
            return "Короче 10 минут"
        }
        let result = durationInMinutes/10 * 10
        return "\(result)–\(result+10) минут"
    }
}

class MdsTrackListController: TrackListControllerBase {
    var sortingMode: SortingMode {
        didSet {
            refreshDataAndNotifyDelegate(changeType: .drasticChange)
        }
    }
    var hideFullyListened: Bool {
        didSet {
            guard hideFullyListened != oldValue else {
                return
            }
            refreshDataAndNotifyDelegate(changeType: hideFullyListened ? .tracksRemoved : .tracksAdded)
        }
    }
    override var headerField: HeaderField {
        switch sortingMode {
        case .author: return .author
        case .station: return .station
        case .date: return .year
        case .durationAsc, .durationDesc: return .duration
        }
    }

    init(sortedBy sortingMode: SortingMode, hideFullyListened: Bool,
         audioPlayer: AudioPlayer = RealAudioPlayer.shared,
         downloadManager: DownloadManager = .shared) {
        self.sortingMode = sortingMode
        self.hideFullyListened = hideFullyListened
        super.init(audioPlayer: audioPlayer, downloadManager: downloadManager)
    }

    override func getData() -> [MdsTrack] {
        var data = hideFullyListened ? getUnfinishedTracks() : getAllTracks()
        data.sort(by: getSortFunc())
        return data
    }

    private func getAllTracks() -> [MdsTrack] { DataStorage.reader.getAllTracks() }
    private func getUnfinishedTracks() -> [MdsTrack] { DataStorage.reader.getUnfinishedTracks() }

    private func getSortFunc() -> (MdsTrack, MdsTrack) -> Bool {
        switch sortingMode {
        case .author:
            return { $0.trackAuthor < $1.trackAuthor || $0.trackAuthor == $1.trackAuthor && $0.trackTitle < $1.trackTitle }
        case .date:
            return { $0.date < $1.date }
        case .station:
            return { $0.station < $1.station || $0.station == $1.station && $0.date < $1.date }
        case .durationAsc:
            return { $0.durationInMinutes < $1.durationInMinutes }
        case .durationDesc:
            return { $0.durationInMinutes > $1.durationInMinutes }
        }
    }

    override func getSectionifyFunc() -> (MdsTrack) -> String? {
        switch sortingMode {
        case .author: return { $0.trackAuthor }
        case .station: return { $0.station }
        case .date: return { $0.date?.yearString }
        case .durationAsc, .durationDesc: return { $0.durationGroup }
        }
    }

    override func getIndexFunc() -> ((String?) -> String)? {
        switch sortingMode {
        case .author: return { $0!.prefix(1).uppercased() }
        case .station: return { $0?.prefix(2).uppercased() ?? ".." }
        case .date: return { $0?.suffix(2).uppercased() ?? ".." }
        case .durationAsc, .durationDesc:
            return {
                guard let duration = Int($0!.prefix(2)) else {
                    return ".."
                }
                return "\(duration)"
            }
        }
    }

    override func dataStorage(didUpdate properties: DataStorageTrackProperties, of track: MdsTrack) {
        super.dataStorage(didUpdate: properties, of: track)
        guard hideFullyListened else {
            // if not hiding fully listened, data storage changes don't affect the list
            return
        }
        if properties.contains(.fullyListened) {
            refreshDataAndNotifyDelegate(changeType: track.fullyListened ? .tracksRemoved : .tracksAdded)
        }
    }

    func randomRow() -> IndexPath? {
        guard let randomTrack = (hideFullyListened ? sortedData : getUnfinishedTracks()).randomElement() else {
            return nil
        }
        return indexPath(of: randomTrack)
    }
}
