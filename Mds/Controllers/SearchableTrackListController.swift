import Foundation

class SearchableTrackListController: TrackListControllerBase {
    override var headerField: HeaderField { .author }

    var searchTerm: String {
        didSet {
            if searchTerm != oldValue {
                refreshDataAndNotifyDelegate(changeType: .drasticChange)
            }
        }
    }

    override init(audioPlayer: AudioPlayer = RealAudioPlayer.shared, downloadManager: DownloadManager = .shared) {
        self.searchTerm = ""
        super.init(audioPlayer: audioPlayer, downloadManager: downloadManager)
    }

    override func getData() -> [MdsTrack] {
        var data = DataStorage.reader.getAllTracks()
        if !searchTerm.isEmpty {
            data = data.filter {
                return $0.trackAuthor.range(of: searchTerm, options: [.caseInsensitive, .diacriticInsensitive], range: nil, locale: Locale.init(identifier: "ru")) != nil
                    || $0.trackTitle.range(of: searchTerm, options: [.caseInsensitive, .diacriticInsensitive], range: nil, locale: Locale.init(identifier: "ru")) != nil
            }
        }
        data.sort { $0.trackAuthor < $1.trackAuthor || $0.trackAuthor == $1.trackAuthor && $0.trackTitle < $1.trackTitle }
        return data
    }

    override func getSectionifyFunc() -> (MdsTrack) -> String? {
        return { $0.trackAuthor }
    }
}
