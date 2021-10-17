import UIKit

final class SearchResultsViewController: TrackListTableViewController {
    fileprivate var searchController: SearchableTrackListController!
    override func viewDidLoad() {
        searchController = SearchableTrackListController()
        controller = searchController
        super.viewDidLoad()
    }
}

final class SearchViewController: UIViewController, UITableViewDataSource, UISearchResultsUpdating, ApplicationStateAwareControllerDelegate, AudioStatusViewDelegate {
    private var migration: MigrationViewController!
    private var controller: ApplicationStateAwareController!
    private var searchController: UISearchController!
    private var searchResultsViewController: SearchResultsViewController!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var statusView: AudioStatusView!

    override func viewDidLoad() {
        controller = ApplicationStateAwareController()
        super.viewDidLoad()
        controller.delegate = self
        statusView.playerDuration = controller.playerDuration
        statusView.playerPosition = controller.playerPosition
        statusView.playerState = controller.playerState
        statusView.sleepTimerEnabled = controller.sleepTimer != nil
        statusView.delegate = self

        searchResultsViewController = SearchResultsViewController()
        searchController = UISearchController(searchResultsController: searchResultsViewController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Модель для сборки"
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        }
        else {
            // Fallback on earlier versions
            tableView.tableHeaderView = searchController.searchBar
        }
        definesPresentationContext = true

        migration = MigrationViewController()
        updateMigrationStatus()
    }

    func updateSearchResults(for searchController: UISearchController) {
        searchResultsViewController.searchController.searchTerm = searchController.searchBar.text ?? ""
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        fatalError("Search view controller contains no items")
    }

    func controller(_ controller: AnyController, didReportError error: Error) {
        // Do nothing. Error will be handled by the search result controller
    }

    func controllerDidUpdateMigrationStatus(_ controller: AnyController) {
        updateMigrationStatus()
    }

    func controllerDidUpdatePlayerState(_ controller: AnyController) {
        statusView.playerState = self.controller.playerState
    }

    func controllerDidReceiveNewPlayerPosition(_ controller: AnyController) {
        statusView.playerPosition = self.controller.playerPosition
    }

    func controllerDidReceiveNewSleepTimerValue(_ controller: AnyController) {
        statusView.sleepTimerEnabled = self.controller.sleepTimer != nil
    }

    func controllerDidReceiveNewPlayerDuration(_ controller: AnyController) {
        statusView.playerDuration = self.controller.playerDuration
    }

    func audioStatusView(didRequest action: AudioStatusViewAction) {
        switch action {
        case .pause:
            controller.pauseCurrent()
        case .play:
            controller.playCurrent()
        case .sleepMenu(let view):
            let sleepMenu = SleepMenu(viewController: self)
            sleepMenu.display(near: view)
        case .highlightTrack:
            // do nothing as this controller does not show any tracks
            break
        case .scrollToPosition(let position):
            controller.playerPosition = position
        }
    }

    private func updateMigrationStatus() {
        if controller.isMigrating {
            migration.present(in: self)
        }
        else {
            migration.dismiss()
        }
    }
}
