import UIKit

fileprivate extension Int64 {
    var asFileSize: String {
        return ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
}

fileprivate func getName(forAction action: TrackAction) -> String {
    switch action {
    case .start: return "Начать воспроизведение"
    case .restart, .restartCurrent: return "Играть сначала"
    case .playCurrent, .recallPosition: return "Продолжить воспроизведение"
    case .pauseCurrent: return "Пауза"
    case .download(let servers): return "Загрузить (\(servers[0].1.asFileSize))"
    case .completeDownloadFromServer(_, let size): return "Продолжить загрузку (\(size.asFileSize))"
    case .cancelDownload: return "Отменить загрузку"
    case .deleteDownloaded: return "Удалить загрузку"
    case .markAsListened: return "Отметить как прослушанное"
    case .markAsNotListened: return "Отметить как непрослушанное"
    }
}

fileprivate extension MdsTrack {
    var authorAndTitle: String {
        return "\(trackAuthor) - \(trackTitle)"
    }
}

class TrackListCore: TrackListControllerDelegate, AudioStatusViewDelegate {
    private let migration = MigrationViewController()
    private let controller: TrackListController
    private let tableView: UITableView
    private let statusView: AudioStatusView?
    private weak var viewController: UIViewController!

    init(controller: TrackListController, tableView: UITableView, statusView: AudioStatusView? = nil, viewController: UIViewController) {
        self.controller = controller
        self.tableView = tableView
        self.statusView = statusView
        self.viewController = viewController
        self.controller.delegate = self
        self.statusView?.playerDuration = controller.playerDuration
        self.statusView?.playerPosition = controller.playerPosition
        self.statusView?.sleepTimerEnabled = controller.sleepTimer != nil
        self.statusView?.playerState = controller.playerState
        self.statusView?.delegate = self

        updateMigrationStatus()
    }

    func numberOfSections() -> Int {
        return controller.numberOfSections() ?? 0
    }
    func numberOfRows(in section: Int) -> Int {
        return controller.numberOfRows(inSection: section)!
    }
    func cellForRow(at indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if let c = tableView.dequeueReusableCell(withIdentifier: "track") {
            cell = c
        }
        else {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "track")
        }
        guard let track = controller[indexPath] else {
            fatalError("Attempt to configure cell without a managed object")
        }
        // Configure the cell with data from the managed object.
        let configurator = CellConfigurator(
            track: track,
            downloadState: controller.getDownloadState(of: track),
            headerField: controller.headerField,
            playerState: controller.playerState)
        configurator.configure(
            titleLabel: cell.textLabel,
            subtitleLabel: cell.detailTextLabel,
            accessoryView: &cell.accessoryView)
        return cell
    }
    func titleForHeader(in section: Int) -> String? {
        return controller.titleForHeader(inSection: section)
    }
    func sectionIndexTitles() -> [String]? {
        return controller.sectionIndexTitles()
    }
    func sectionForSectionIndex(title: String, at index: Int) -> Int {
        guard let result = controller.section(forSectionIndexTitle: title, at: index) else {
            fatalError("Unable to locate section for \(title) at index: \(index)")
        }
        return result
    }
    func didSelectRow(at indexPath: IndexPath) {
        guard let track = controller[indexPath] else {
            fatalError("Tapped on a cell without a managed object")
        }
        // HACK: wait until the row becomes visible. Is there a better solution?
        asyncRetry(every: .milliseconds(100), until: .now() + 5) {
            guard let cell = self.tableView.cellForRow(at: indexPath) else {
                return false
            }
            self.controller.activate(track, view: cell)
            return true
        }
    }

    func controllerDidDrasticallyChangeData(_ controller: AnyController) {
        tableView.reloadData()
        (viewController as? MainViewController)?.controllerDidChangeCount(controller)
    }
    func controller(_ controller: AnyController,
        didRemoveSections removedSections: IndexSet,
        andRowsAt removedRows: [IndexPath]) {
        tableView.beginUpdates()
        tableView.deleteRows(at: removedRows, with: .top)
        tableView.deleteSections(removedSections, with: .top)
        tableView.endUpdates()
        (viewController as? MainViewController)?.controllerDidChangeCount(controller)
    }
    func controller(_ controller: AnyController,
        didAddSections addedSections: IndexSet,
        andRowsAt addedRows: [IndexPath]) {
        tableView.beginUpdates()
        tableView.insertSections(addedSections, with: .top)
        tableView.insertRows(at: addedRows, with: .top)
        tableView.endUpdates()
        (viewController as? MainViewController)?.controllerDidChangeCount(controller)
    }
    func controller(_ controller: AnyController, didUpdateRowsAt indexPaths: [IndexPath]) {
        UIView.performWithoutAnimation {
            tableView.reloadRows(at: indexPaths, with: .none)
        }
    }
    func controller(_ controller: AnyController, didMoveRowAt indexPath: IndexPath, to newIndexPath: IndexPath) {
        tableView.moveRow(at: indexPath, to: newIndexPath)
    }
    func controllerDidUpdatePlayerState(_ controller: AnyController) {
        statusView?.playerState = self.controller.playerState
    }
    func controllerDidReceiveNewPlayerPosition(_ controller: AnyController) {
        statusView?.playerPosition = self.controller.playerPosition
    }
    func controllerDidReceiveNewPlayerDuration(_ controller: AnyController) {
        statusView?.playerDuration = self.controller.playerDuration
    }
    func controllerDidReceiveNewSleepTimerValue(_ controller: AnyController) {
        statusView?.sleepTimerEnabled = self.controller.sleepTimer != nil
    }
    func controller(_ controller: AnyController, didReportError error: Error) {
        let alert = UIAlertController(title: "Ошибка", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК", style: .default, handler: nil))
        viewController.present(alert, animated: true, completion: nil)
    }
    func controllerDidUpdateMigrationStatus(_ controller: AnyController) {
        updateMigrationStatus()
    }
    func controller(_ controller: AnyController, selectActionFor track:MdsTrack, from availableActions: [TrackAction], near view: Any?, answerCallback: @escaping (TrackAction) -> Void) {
        func deselectRow() {
            guard let selectedRow = tableView.indexPathForSelectedRow else {
                return
            }
            tableView.deselectRow(at: selectedRow, animated: true)
        }
        let alert = UIAlertController(title: nil, message: track.authorAndTitle, preferredStyle: .actionSheet)
        if let view = view as? UIView {
            alert.popoverPresentationController?.sourceView = view
            alert.popoverPresentationController?.sourceRect = view.bounds
        }
        for action in availableActions {
            let name = getName(forAction: action)
            alert.addAction(UIAlertAction(title: name, style: .default) { _ in
                deselectRow()
                answerCallback(action)
            })
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel) { _ in
            deselectRow()
        })
        viewController.present(alert, animated: true, completion: nil)
    }
    func controller(_ controller: AnyController, confirmDownloadOf track: MdsTrack, withNewSize newSize: Int64, callbackIfYes: @escaping () -> Void, callbackIfNo: @escaping () -> Void) {
        let alert = UIAlertController(title: "Внимание", message: "Проблемы с подключением к серверу. Размер загрузки увеличится до \(newSize.asFileSize).\nПродолжить?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Да", style: .default) { _ in
            callbackIfYes()
        })
        alert.addAction(UIAlertAction(title: "Нет", style: .cancel) { _ in
            callbackIfNo()
        })
        // TODO: No callback is called when alert controller cannot be presented - fix!
        viewController.present(alert, animated: true, completion: nil)
    }

    func audioStatusView(didRequest action: AudioStatusViewAction) {
        switch action {
        case .pause:
            controller.pauseCurrent()
        case .play:
            controller.playCurrent()
        case .sleepMenu(let view):
            let sleepMenu = SleepMenu(viewController: viewController)
            sleepMenu.display(near: view)
        case .highlightTrack(let track):
            guard let idx = controller.indexPath(of: track) else {
                return
            }
            tableView.selectRow(at: idx, animated: true, scrollPosition: .top)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                guard self.tableView.indexPathForSelectedRow == idx else {
                    return
                }
                self.tableView.deselectRow(at: idx, animated: true)
            }
        case .scrollToPosition(let position):
            controller.playerPosition = position
        }
    }

    private func updateMigrationStatus() {
        if controller.isMigrating {
            migration.present(in: viewController)
        }
        else {
            migration.dismiss()
        }
    }
}

