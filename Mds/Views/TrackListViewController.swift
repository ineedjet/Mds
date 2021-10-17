import UIKit

class TrackListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private var core: TrackListCore!
    var controller: TrackListController!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var statusView: AudioStatusView!

    override func viewDidLoad() {
        assert(controller != nil, "Please override `TrackListViewController.viewDidLoad()` and set controller property before calling `super.viewDidLoad()`")
        assert(tableView != nil, "Please connect `tableView` outlet in Interface Builder")
        assert(statusView != nil, "Please connect `statusView` outlet in Interface Builder")
        super.viewDidLoad()
        core = TrackListCore(controller: controller, tableView: tableView, statusView: statusView, viewController: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let statusViewHeight = statusView.frame.height
        let bottomInset: CGFloat
        if #available(iOS 11.0, *) {
            bottomInset = statusViewHeight
        }
        else {
            let tabBarHeight = tabBarController?.tabBar.frame.height ?? 0
            bottomInset = tabBarHeight + statusViewHeight
        }
        tableView.scrollIndicatorInsets.bottom = bottomInset
        tableView.contentInset.bottom = bottomInset
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return core.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return core.numberOfRows(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return core.cellForRow(at: indexPath)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return core.titleForHeader(in: section)
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return core.sectionIndexTitles()
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return core.sectionForSectionIndex(title: title, at: index)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        return core.didSelectRow(at: indexPath)
    }
}
