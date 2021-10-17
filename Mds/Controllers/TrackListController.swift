import Foundation

protocol TrackListControllerDelegate: TrackActivatingControllerDelegate {
    func controllerDidDrasticallyChangeData(_ controller: AnyController)
    func controller(_ controller: AnyController, didUpdateRowsAt indexPaths: [IndexPath])
    func controller(_ controller: AnyController,
        didRemoveSections sections: IndexSet,
        andRowsAt indexPaths: [IndexPath])
    func controller(_ controller: AnyController,
        didAddSections addedSections: IndexSet,
        andRowsAt addedRows: [IndexPath])
    func controller(_ controller: AnyController, didMoveRowAt indexPath: IndexPath, to newIndexPath: IndexPath)
}

enum HeaderField {
    case none
    case year
    case author
    case station
    case duration
    case lastListened
    case downloadState
}

protocol TrackListController: AnyObject {
    var delegate: AnyControllerDelegate? { get set }
    var isMigrating: Bool { get }

    var playerState: AudioPlayerState { get }
    var playerPosition: Double { get set }
    var playerDuration: Double { get }
    var sleepTimer: TimeInterval? { get }
    func activate(_ track: MdsTrack, view: Any?)
    func pauseCurrent()
    func playCurrent()

    var headerField: HeaderField { get }
    func numberOfSections() -> Int?
    func numberOfRows(inSection section: Int) -> Int?
    func titleForHeader(inSection section: Int) -> String?
    func sectionIndexTitles() -> [String]?
    func section(forSectionIndexTitle title: String, at index: Int) -> Int?
    subscript(_ indexPath: IndexPath) -> MdsTrack? { get }

    func indexPath(of track: MdsTrack) -> IndexPath?
    func getDownloadState(of track: MdsTrack) -> DownloadState
}
