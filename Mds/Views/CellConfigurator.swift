import UIKit

fileprivate var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateStyle = .medium
    return formatter
}()

fileprivate var dateFormatterWithoutYear: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMMd", options: 0, locale: Locale.current)
    return formatter
}()

fileprivate let accessoryFont = UIFont.systemFont(ofSize: 12)

fileprivate extension MdsTrack {
    var dateStationAndShortDesc: String {
        if let date = date {
            if let station = station {
                return "\(dateFormatter.string(from: date)) (\(station)) - \(shortDesc)"
            }
            return "\(dateFormatter.string(from: date)) - \(shortDesc)"
        }
        if let station = station {
            return "(\(station)) - \(shortDesc)"
        }
        return shortDesc
    }
    var shortDesc: String {
        let h = durationInMinutes/60
        let m = durationInMinutes%60
        return (h > 0 ? "\(h) ч. " : "") + (m > 0 ? "\(m) мин." : "")
    }
    var shortDateAuthorAndShortDesc: String {
        if let date = date {
            return "\(dateFormatterWithoutYear.string(from: date)) - \(trackAuthor) - \(shortDesc)"
        }
        return "\(trackAuthor) - \(shortDesc)"
    }
    var dateAuthorAndShortDesc: String {
        if let date = date {
            return "\(dateFormatter.string(from: date)) - \(trackAuthor) - \(shortDesc)"
        }
        return "\(trackAuthor) - \(shortDesc)"
    }
}

final class CellConfigurator {
    private let track: MdsTrack
    private let downloadState: DownloadState
    private let headerField: HeaderField
    private let playerState: AudioPlayerState

    init(track: MdsTrack, downloadState: DownloadState, headerField: HeaderField, playerState: AudioPlayerState) {
        self.track = track
        self.downloadState = downloadState
        self.headerField = headerField
        self.playerState = playerState
    }

    func configure(titleLabel: UILabel?, subtitleLabel: UILabel?, accessoryView: inout UIView?) {
        if track.fullyListened {
            titleLabel?.textColor = .safeSecondaryLabel
            subtitleLabel?.textColor = .safeSecondaryLabel
        }
        else {
            titleLabel?.textColor = .safeLabel
            subtitleLabel?.textColor = .safeLabel
        }
        titleLabel?.text = track.trackTitle
        var accView: UIView? = nil
        switch headerField {
        case .author:
            subtitleLabel?.text = track.dateStationAndShortDesc
        case .year:
            subtitleLabel?.text = track.shortDateAuthorAndShortDesc
        case .station, .lastListened:
            subtitleLabel?.text = track.dateAuthorAndShortDesc
        case .duration:
            subtitleLabel?.text = track.dateAuthorAndShortDesc
        case .downloadState:
            subtitleLabel?.text = track.dateAuthorAndShortDesc
            if case let .corrupted(totalSize) = downloadState {
                accView = getLabel(fileSize: totalSize)
            }
            if case let .downloaded(_, totalSize) = downloadState {
                accView = getLabel(fileSize: totalSize)
            }
        default:
            fatalError("View Controller can't display a track when header field is \(headerField)!")
        }
        switch playerState {
        case let .preparing(curTrack) where curTrack == track,
             let .loading(curTrack) where curTrack == track:
            accessoryView = getSpinner()
        case let .playing(curTrack) where curTrack == track:
            accessoryView = getPlaySign()
        case let .paused(curTrack) where curTrack == track,
             let .selected(curTrack, _) where curTrack == track:
            accessoryView = getPauseSign()
        default:
            accessoryView = accView
        }
    }
    private func getSpinner() -> UIView {
        let view = UIActivityIndicatorView(style: .safeMedium)
        view.startAnimating()
        return view
    }
    private func getPlaySign() -> UIView {
        if #available(iOS 13.0, *) {
            let image = UIImage(systemName: "play.fill")
            let view = UIImageView(image: image)
            view.tintColor = .label
            return view
        } else {
            return UIImageView(image: #imageLiteral(resourceName: "play.png"))
        }
    }
    private func getPauseSign() -> UIView {
        if #available(iOS 13.0, *) {
            let image = UIImage(systemName: "pause.fill")
            let view = UIImageView(image: image)
            view.tintColor = .label
            return view
        } else {
            return UIImageView(image: #imageLiteral(resourceName: "pause.png"))
        }
    }
    private func getLabel(fileSize: Int64) -> UIView {
        let formatterBytes = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        let frameSize = (formatterBytes as NSString).size(withAttributes: [.font: accessoryFont])
        let view = UILabel(frame: CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height))
        view.font = accessoryFont
        view.text = formatterBytes
        return view
    }
}
