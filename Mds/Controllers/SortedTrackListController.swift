import Foundation

/** `MdsTrackListController` that follows current sort settings */
final class SortedTrackListController: MdsTrackListController {
    private var sortingModeObservation: NSKeyValueObservation!
    private var hideFullyListenedObservation: NSKeyValueObservation!
    init() {
        super.init(sortedBy: UserDefaults.standard.sortingMode, hideFullyListened: UserDefaults.standard.hideFullyListened)

        sortingModeObservation = UserDefaults.standard.observe(\.rawSortingMode) { [weak self] (_,_) in
            self?.sortingMode = UserDefaults.standard.sortingMode
        }
        hideFullyListenedObservation = UserDefaults.standard.observe(\.hideFullyListened) { [weak self] (_,_) in
            self?.hideFullyListened = UserDefaults.standard.hideFullyListened
        }
    }
}
