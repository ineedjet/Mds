import UIKit

final class MainViewController: TrackListViewController {
    private var trackListController: MdsTrackListController!
    private var footerLabel: UILabel!
    override func viewDidLoad() {
        trackListController = SortedTrackListController()
        controller = trackListController
        super.viewDidLoad()

        let footerRect = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 66)
        let footer = UIView(frame: footerRect)
        let labelRect = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44)
        footerLabel = UILabel(frame: labelRect)
        footerLabel.textAlignment = .center
        footerLabel.font = .systemFont(ofSize: 20)
        footerLabel.textColor = .safeSecondaryLabel
        footer.addSubview(footerLabel)
        tableView.tableFooterView = footer

        updateFooterAndHeaderText()
    }

    private func updateFooterAndHeaderText() {
        if trackListController.visibleTracks == trackListController.totalTracks {
            footerLabel.text = getRussianString(forNumber: trackListController.totalTracks, andNounForms: ("запись", "записи", "записей"))
        }
        else {
            footerLabel.text = "Показано: \(getRussianString(forNumber: trackListController.visibleTracks, andNounForms: ("запись", "записи", "записей"))) из \(trackListController.totalTracks)"
        }
        navigationItem.title = trackListController.hideFullyListened ? "Непрослушанные" : "Все записи"
    }

    func controllerDidChangeCount(_ controller: AnyController) {
        updateFooterAndHeaderText()
    }

    @IBAction func diceTapped() {
        guard let idx = trackListController.randomRow() else {
            let alert = UIAlertController(title: "Внимание", message: "Не осталось непрослушанных записей", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ОК", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        tableView.selectRow(at: idx, animated: true, scrollPosition: .top)
        tableView(tableView, didSelectRowAt: idx)
    }
}
