import UIKit

final class DownloadsViewController: TrackListViewController {
    override func viewDidLoad() {
        controller = DownloadListController()
        super.viewDidLoad()
    }

    private func getCell(forTrack track: MdsTrack, withDownloadState downloadState: DownloadState, andProgress progress: Progress?) -> UITableViewCell {
        let cell: DownloadTableViewCell
        if let c = tableView.dequeueReusableCell(withIdentifier: "download") as? DownloadTableViewCell {
            cell = c
        }
        else {
            cell = DownloadTableViewCell(style: .default, reuseIdentifier: "download")
        }
        // Configure the cell with data from the managed object.
        let configurator = CellConfigurator(
            track: track,
            downloadState: downloadState,
            headerField: controller.headerField,
            playerState: controller.playerState)
        configurator.configure(
            titleLabel: cell.titleLabel,
            subtitleLabel: cell.subtitleLabel,
            accessoryView: &cell.accessoryView)
        if let progress = progress {
            // subscribe to progress updates
            cell.progress.observedProgress = progress
            // update current progress immediately
            cell.progress.progress = Float(progress.fractionCompleted)
            cell.progress.isHidden = false
        }
        else {
            cell.progress.isHidden = true
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let track = controller[indexPath] else {
            fatalError("No track at given indexPath")
        }
        let downloadState = controller.getDownloadState(of: track)
        if case let .downloading(_, progress) = downloadState {
            return getCell(forTrack: track, withDownloadState: downloadState, andProgress: progress)
        }
        if case let .incomplete(_, progress) = downloadState {
            return getCell(forTrack: track, withDownloadState: downloadState, andProgress: progress)
        }
        return getCell(forTrack: track, withDownloadState: downloadState, andProgress: nil)
    }
}

