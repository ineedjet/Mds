import Foundation

fileprivate enum DownloadUIState {
    case unknown
    case pending
    case paused
    case corrupted
    case finished
}

fileprivate let OrderedHeaderTitle: [DownloadUIState]  = [
    .pending,
    .corrupted,
    .paused,
    .finished,
]

fileprivate let HeaderTitle : [DownloadUIState : String] = [
    .pending : "В процессе",
    .finished : "Завершенные",
    .paused : "Незавершенные",
    .corrupted : "Поврежденные",
]

final class DownloadListController: TrackActivatingController, TrackListController {
    private weak var trackListControllerDelegate: TrackListControllerDelegate? {
        return delegate as? TrackListControllerDelegate
    }
    private var sections: [DownloadUIState] = []
    private var allItems: [DownloadUIState:[DownloadItem]] = [:]

    let headerField: HeaderField = .downloadState

    override init(audioPlayer: AudioPlayer = RealAudioPlayer.shared, downloadManager: DownloadManager = .shared) {
        super.init(audioPlayer: audioPlayer, downloadManager: downloadManager)
        refreshData()
        NotificationCenter.default.addObserver(self, selector: #selector(downloadManagerDidUpdateCache), name: .downloadManagerDidUpdateCache, object: nil)
    }

    private func refreshData() {
        allItems = Dictionary(grouping: downloadManager.getDownloads()) {
            switch $0.state {
            case .downloading, .preparing: return .pending
            case .downloaded: return .finished
            case .incomplete: return .paused
            case .corrupted: return .corrupted
            default: return .unknown
            }
        }
        sections = []
        for state in OrderedHeaderTitle {
            if let c = allItems[state]?.count, c > 0 {
                sections.append(state)
            }
        }
        // TODO: Optimize
        trackListControllerDelegate?.controllerDidDrasticallyChangeData(self)
    }

    override func audioPlayerDidChangeState(from: AudioPlayerState?) {
        // TODO: Optimize
        trackListControllerDelegate?.controllerDidDrasticallyChangeData(self)
    }

    func numberOfSections() -> Int? {
        return sections.count
    }

    func numberOfRows(inSection section: Int) -> Int? {
        return allItems[sections[section]]?.count
    }

    func titleForHeader(inSection section: Int) -> String? {
        return HeaderTitle[sections[section]]
    }

    func sectionIndexTitles() -> [String]? {
        return nil
    }

    func section(forSectionIndexTitle title: String, at index: Int) -> Int? {
        return nil
    }

    subscript(indexPath: IndexPath) -> MdsTrack? {
        guard let id = allItems[sections[indexPath.section]]?[indexPath.row].trackId else {
            return nil
        }
        return DataStorage.reader.tryGetTrack(withId: id)
    }

    func indexPath(of track: MdsTrack) -> IndexPath? {
        for (section, sectionTitle) in sections.enumerated() {
            guard let items = allItems[sectionTitle] else {
                // inconsistency detected. Better be safe than sorry
                return nil
            }
            for (row, item) in items.enumerated() {
                if item.trackId == track.trackId {
                    return IndexPath(row: row, section: section)
                }
            }
        }
        return nil
    }

    @objc private func downloadManagerDidUpdateCache() {
        refreshData()
    }
}
