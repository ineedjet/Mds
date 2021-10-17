import Foundation

/*abstract*/ class TrackListControllerBase : TrackActivatingController, TrackListController {
    weak var trackListControllerDelegate: TrackListControllerDelegate? {
        return delegate as? TrackListControllerDelegate
    }

    private class Section {
        let title: String?
        let start: Int
        var count: Int
        init(title: String?, start: Int) {
            self.title = title
            self.start = start
            self.count = 1
        }
    }

    private struct IndexSection {
        let title: String
        let start: Int
    }

    enum ChangeType {
        case tracksAdded
        case tracksRemoved
        case drasticChange
    }

    private(set) var sortedData: [MdsTrack] = []
    private var dataLocations: [TrackId:IndexPath] = [:]
    private var sections: [Section] = []
    private var indexSections: [IndexSection]? = nil

    override init(audioPlayer: AudioPlayer = RealAudioPlayer.shared, downloadManager: DownloadManager = .shared) {
        super.init(audioPlayer: audioPlayer, downloadManager: downloadManager)
        NotificationCenter.default.addObserver(self, selector: #selector(dataStorageDidUpdateTrack), name: .dataStorageDidUpdateTrack, object: nil)
        refreshData()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    var totalTracks: Int {
        return DataStorage.reader.getTotalTrackCount()
    }
    var visibleTracks: Int {
        return sortedData.count
    }

    /*abstract*/ var headerField: HeaderField {
        fatalError("Property `headerField` needs to be implemented by the subclass")
    }

    /*abstract*/ func getData() -> [MdsTrack] {
        fatalError("Method `getData()` needs to be implemented by the subclass")
    }

    /*abstract*/ func getSectionifyFunc() -> (MdsTrack) -> String? {
        fatalError("Method `getSectionifyFunc()` needs to be implemented by the subclass")
    }

    func getIndexFunc() -> ((String?) -> String)? {
        return nil
    }

    private func refreshData() {
        sortedData = getData()

        // build sections
        let sectionify = getSectionifyFunc()
        sections = []
        dataLocations = [:]
        for (i, item) in sortedData.enumerated() {
            let sectionTitle = sectionify(item)
            guard let section = sections.last, sectionTitle == section.title else {
                sections.append(Section(title: sectionTitle, start: i))
                dataLocations[item.trackId] = IndexPath(row: 0, section: sections.count-1)
                continue
            }
            section.count += 1
            dataLocations[item.trackId] = IndexPath(row: section.count-1, section: sections.count-1)
        }

        // build index sections
        if let index = getIndexFunc() {
            var indexSections: [IndexSection] = []
            for (i, section) in sections.enumerated() {
                let indexSectionTitle = index(section.title)
                guard let indexSection = indexSections.last, indexSectionTitle == indexSection.title else {
                    indexSections.append(IndexSection(title: indexSectionTitle, start: i))
                    continue
                }
            }
            self.indexSections = indexSections
        }
        else {
            indexSections = nil
        }
    }

    private func refreshDataBecauseOfDrasticChange() {
        refreshData()
        trackListControllerDelegate?.controllerDidDrasticallyChangeData(self)
    }

    private func refreshDataBecauseTracksWereAdded() {
        let oldData = sortedData
        let oldSections = sections
        refreshData()
        guard let newTracks = sortedData.subtract(oldData, comparingBy: {$0.trackId == $1.trackId}) else {
            print("Tracks were added, but new data is not a superset of old data")
            trackListControllerDelegate?.controllerDidDrasticallyChangeData(self)
            return
        }
        guard let newSections = sections.subtract(oldSections, comparingBy: {$0.title == $1.title}) else {
            print("Tracks were added, but new section list is not a superset of old section list")
            trackListControllerDelegate?.controllerDidDrasticallyChangeData(self)
            return
        }
        let newRows = newTracks.map{indexPath(of: sortedData[$0])!}.filter{!newSections.contains($0.section)}
        if newSections.count > 0 || newRows.count > 0 {
            trackListControllerDelegate?.controller(self, didAddSections: IndexSet(newSections), andRowsAt: newRows)
        }
    }

    private func refreshDataBecauseTracksWereRemoved() {
        let oldData = sortedData
        let oldDataLocations = dataLocations
        let oldSections = sections
        refreshData()
        guard let removedTracks = oldData.subtract(sortedData, comparingBy: {$0.trackId == $1.trackId}) else {
            print("Tracks were added, but new data is not a subset of old data")
            trackListControllerDelegate?.controllerDidDrasticallyChangeData(self)
            return
        }
        guard let removedSections = oldSections.subtract(sections, comparingBy: {$0.title == $1.title}) else {
            print("Tracks were added, but new section list is not a subset of old section list")
            trackListControllerDelegate?.controllerDidDrasticallyChangeData(self)
            return
        }
        let removedRows = removedTracks.map{oldDataLocations[oldData[$0].trackId]!}.filter{!removedSections.contains($0.section)}
        if removedSections.count > 0 || removedRows.count > 0 {
            trackListControllerDelegate?.controller(self, didRemoveSections: IndexSet(removedSections), andRowsAt: removedRows)
        }
    }

    func refreshDataAndNotifyDelegate(changeType: ChangeType) {
        switch changeType {
        case .tracksAdded:
            refreshDataBecauseTracksWereAdded()
        case .tracksRemoved:
            refreshDataBecauseTracksWereRemoved()
        case .drasticChange:
            refreshDataBecauseOfDrasticChange()
        }
    }

    func numberOfSections() -> Int? {
        return sections.count
    }

    func numberOfRows(inSection section: Int) -> Int? {
        return sections[section].count
    }

    func titleForHeader(inSection section: Int) -> String? {
        return sections[section].title ?? ""
    }

    func sectionIndexTitles() -> [String]? {
        return indexSections?.map { $0.title }
    }

    func section(forSectionIndexTitle title: String, at index: Int) -> Int? {
        return indexSections?[index].start
    }

    subscript(_ indexPath: IndexPath) -> MdsTrack? {
        return sortedData[sections[indexPath.section].start + indexPath.row]
    }

    func indexPath(of track: MdsTrack) -> IndexPath? {
        return dataLocations[track.trackId]
    }

    @objc private func dataStorageDidUpdateTrack(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let track = userInfo[DataStorageTrackKey] as? MdsTrack,
            let properties = userInfo[DataStoragePropertiesKey] as? DataStorageTrackProperties else {
            return
        }
        dataStorage(didUpdate: properties, of: track)
    }

    func dataStorage(didUpdate properties: DataStorageTrackProperties, of track: MdsTrack) {
        guard properties.contains(.fullyListened),
              let indexPath = indexPath(of: track) else {
            return
        }
        trackListControllerDelegate?.controller(self, didUpdateRowsAt: [indexPath])
    }

    override func audioPlayerDidChangeState(from oldState: AudioPlayerState?) {
        var affectedTracks = Set<IndexPath>()
        switch oldState {
        case .preparing(let t), .loading(let t), .playing(let t), .paused(let t), .selected(let t, _):
            if let indexPath = indexPath(of: t) {
                affectedTracks.insert(indexPath)
            }
        case .error, .idle, nil:
            break
        }
        switch playerState {
        case .preparing(let t), .loading(let t), .playing(let t), .paused(let t), .selected(let t, _):
            if let indexPath = indexPath(of: t) {
                affectedTracks.insert(indexPath)
            }
        case .error, .idle:
            break
        }
        trackListControllerDelegate?.controller(self, didUpdateRowsAt: Array(affectedTracks))
    }
}
