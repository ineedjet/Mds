import UIKit

final class SettingsViewController: UITableViewController {
    @IBOutlet var sortByAuthorCell: UITableViewCell!
    @IBOutlet var sortByDateCell: UITableViewCell!
    @IBOutlet var sortByStationCell: UITableViewCell!
    @IBOutlet var sortByDurationAscCell: UITableViewCell!
    @IBOutlet var sortByDurationDescCell: UITableViewCell!
    @IBOutlet var hideFullyListenedSwitch: UISwitch!

    private var sortingModeObservation: NSKeyValueObservation!
    private var hideFullyListenedObservation: NSKeyValueObservation!

    override func viewDidLoad() {
        sortingModeObservation = UserDefaults.standard.observe(\.rawSortingMode) { [weak self] (_,_) in
            self?.refreshSortingMode()
        }
        hideFullyListenedObservation = UserDefaults.standard.observe(\.hideFullyListened) { [weak self] (_,_) in
            self?.refreshFilters()
        }
        refreshSortingMode()
        refreshFilters()
    }

    func refreshSortingMode() {
        let sortingMode = UserDefaults.standard.sortingMode
        sortByDateCell.accessoryType = sortingMode == .date ? .checkmark : .none
        sortByAuthorCell.accessoryType = sortingMode == .author ? .checkmark : .none
        sortByStationCell.accessoryType = sortingMode == .station ? .checkmark : .none
        sortByDurationAscCell.accessoryType = sortingMode == .durationAsc ? .checkmark : .none
        sortByDurationDescCell.accessoryType = sortingMode == .durationDesc ? .checkmark : .none
    }

    func refreshFilters() {
        hideFullyListenedSwitch.isOn = UserDefaults.standard.hideFullyListened
    }

    @IBAction func tapDone(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func switchTheSwitch(_ sender: Any) {
        UserDefaults.standard.hideFullyListened = hideFullyListenedSwitch.isOn
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableView.cellForRow(at: indexPath) {
        case .some(sortByAuthorCell):
            UserDefaults.standard.sortingMode = .author
        case .some(sortByDateCell):
            UserDefaults.standard.sortingMode = .date
        case .some(sortByStationCell):
            UserDefaults.standard.sortingMode = .station
        case .some(sortByDurationAscCell):
            UserDefaults.standard.sortingMode = .durationAsc
        case .some(sortByDurationDescCell):
            UserDefaults.standard.sortingMode = .durationDesc
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
