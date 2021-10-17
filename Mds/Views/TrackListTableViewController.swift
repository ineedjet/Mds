import UIKit

class TrackListTableViewController: UITableViewController {
    private var core: TrackListCore!
    var controller: TrackListController!

    override func viewDidLoad() {
        assert(controller != nil, "Please override `TrackListViewController.viewDidLoad()` and set controller property before calling `super.viewDidLoad()`")
        super.viewDidLoad()
        core = TrackListCore(controller: controller, tableView: tableView, viewController: self)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return core.numberOfSections()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return core.numberOfRows(in: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return core.cellForRow(at: indexPath)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return core.titleForHeader(in: section)
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return core.sectionIndexTitles()
    }

    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return core.sectionForSectionIndex(title: title, at: index)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        return core.didSelectRow(at: indexPath)
    }
}
