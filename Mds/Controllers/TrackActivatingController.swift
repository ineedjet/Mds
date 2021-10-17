import Foundation

protocol TrackActivatingControllerDelegate: ApplicationStateAwareControllerDelegate {
    func controller(_ controller: AnyController, selectActionFor track: MdsTrack, from availableActions: [TrackAction], near view: Any?, answerCallback: @escaping (TrackAction) -> Void)
    func controller(_ controller: AnyController, confirmDownloadOf track:MdsTrack, withNewSize newSize: Int64, callbackIfYes: @escaping () -> Void, callbackIfNo: @escaping () -> Void)
}

enum TrackAction {
    case pauseCurrent
    case playCurrent
    case restartCurrent
    case markAsListened
    case markAsNotListened
    case start
    case restart
    case recallPosition(ServerId)
    case completeDownloadFromServer(ServerId, Int64)
    case download([(ServerId, Int64)])
    case cancelDownload
    case deleteDownloaded
}

fileprivate struct NoServersFoundError: LocalizedError {
    var errorDescription: String? {
        return "Не удалось подключиться к серверу. Пожалуйста попробуйте позднее"
    }
}

func isComparable(fileSize: Int64, toExpectedSize expected: Int64) -> Bool {
    return fileSize < expected + 5*1024*1024 || fileSize < expected * 120 / 100
}

fileprivate let BackgroundQueue = DispatchQueue(label: "net.samarkin.Mds.TrackActivatingController.BackgroundQueue")

class TrackActivatingController: ApplicationStateAwareController {
    private weak var trackActivatingDelegate: TrackActivatingControllerDelegate? {
        return delegate as? TrackActivatingControllerDelegate
    }

    func activate(_ track: MdsTrack, view: Any?) {
        var availableActions: [TrackAction] = []
        if case let .playing(curTrack) = playerState, curTrack == track {
            // currently playing
            availableActions.append(.pauseCurrent)
            availableActions.append(.restartCurrent)
        }
        else if case let .paused(curTrack) = playerState, curTrack == track {
            // currently paused
            availableActions.append(.playCurrent)
            availableActions.append(.restartCurrent)
        }
        else if case let .selected(curTrack, _) = playerState, curTrack == track {
            // currently pre-selected
            availableActions.append(.playCurrent)
            availableActions.append(.restartCurrent)
        }
        else if let serverId = track.lastServerId, track.lastPosition > 0 {
            // non-current with saved position
            availableActions.append(.recallPosition(serverId))
            availableActions.append(.restart)
        }
        else {
            // non-current without saved position
            availableActions.append(.start)
        }
        if !track.fullyListened {
            availableActions.append(.markAsListened)
        }
        else {
            availableActions.append(.markAsNotListened)
        }
        switch downloadManager.getDownloadState(track) {
        case .notDownloaded:
            let servers = track.getServersWithSizes()
            if servers.count > 0 {
                availableActions.append(.download(servers))
            }
        case .downloaded:
            availableActions.append(.deleteDownloaded)
        case .downloading, .preparing:
            availableActions.append(.cancelDownload)
        case .corrupted:
            availableActions.append(.deleteDownloaded)
        case let .incomplete(server, progress):
            availableActions.append(.completeDownloadFromServer(server, progress.totalUnitCount - progress.completedUnitCount))
            availableActions.append(.deleteDownloaded)
        }
        trackActivatingDelegate?.controller(self, selectActionFor: track, from: availableActions, near: view) { [weak self] in
            self?.processAction($0, forTrack: track)
        }
    }

    private func download(track: MdsTrack, from serversWithSizes: [(ServerId, Int64)]) {
        let expectedSize = serversWithSizes[0].1
        let downloadManager = self.downloadManager
        downloadManager.prepareDownload(ofTrack: track)
        selectServer(forTrack: track) { [weak self] in
            guard let (server, realSize) = $0 else {
                downloadManager.cancelPreparation(ofTrack: track, becauseOf: NoServersFoundError())
                return
            }
            if isComparable(fileSize: realSize, toExpectedSize: expectedSize) {
                downloadManager.download(track, from: server, onlyIfPrepared: true)
                return
            }
            DispatchQueue.main.async {
                guard let strongSelf = self else {
                    downloadManager.cancelPreparation(ofTrack: track)
                    return
                }
                strongSelf.trackActivatingDelegate?.controller(strongSelf, confirmDownloadOf: track, withNewSize: realSize, callbackIfYes: {
                    downloadManager.download(track, from: server, onlyIfPrepared: true)
                }, callbackIfNo: {
                    downloadManager.cancelPreparation(ofTrack: track)
                })
            }
        }
    }

    // TODO: Move to DownloadManager?
    // callback is always called on BackgroundQueue
    private func selectServer(forTrack track: MdsTrack, callback: @escaping ((ServerId, Int64)?) -> Void) {
        var foundServer = false
        let downloadManager = self.downloadManager
        asyncForEach(in: track.getServersWithSizes(), callbackQueue: BackgroundQueue, finish: {
            if !foundServer {
                callback(nil)
            }
        }) { (arg0, nextServer) in
            let (server, _) = arg0
            downloadManager.estimateSize(ofTrack: track, fromServer: server) {
                guard let realSize = $0, realSize > 102400 else {
                    // continue
                    nextServer()
                    return
                }
                foundServer = true
                callback((server, realSize))
            }
        }
    }

    // callback is always called on MainQueue
    private func getBestServer(forTrack track: MdsTrack, callback: @escaping (ServerId?) -> Void) {
        switch downloadManager.getDownloadState(track) {
        case .notDownloaded, .corrupted:
            selectServer(forTrack: track) {
                guard let (server, _) = $0 else {
                    DispatchQueue.main.async {
                        callback(nil)
                    }
                    return
                }
                DispatchQueue.main.async {
                    callback(server)
                }
            }
            break
        case .preparing:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in // retry in a second
                self?.getBestServer(forTrack: track, callback: callback)
            }
            break
        case .downloading(let server, _):
            callback(server)
            break
        case .incomplete(let server, _):
            callback(server)
            break
        case .downloaded(let server, _):
            callback(server)
            break
        }
    }

    func processAction(_ selectedAction: TrackAction, forTrack track: MdsTrack) {
        switch selectedAction {
        case .playCurrent:
            audioPlayer.play()
        case .pauseCurrent:
            audioPlayer.pause()
        case .restartCurrent:
            audioPlayer.setPosition(0)
            audioPlayer.play()
        case .start, .restart:
            DataStorage.writer.set(lastListened: Date(), forTrack: track)
            audioPlayer.prepare(track)
            getBestServer(forTrack: track) { [weak self] serverId in
                guard let strongSelf = self,
                    case let .preparing(t) = strongSelf.playerState,
                    t.trackId == track.trackId
                    else {
                    return
                }
                guard let serverId = serverId else {
                    strongSelf.audioPlayer.cancelPreparation(ofTrack: track, becauseOf: NoServersFoundError())
                    return
                }
                DataStorage.writer.set(lastPosition: 0, lastServerId: serverId, forTrack: track)
                strongSelf.audioPlayer.load(track, fromServer: serverId)
            }
        case let .recallPosition(serverId):
            DataStorage.writer.set(lastListened: Date(), forTrack: track)
            audioPlayer.load(track, fromServer: serverId)
        case let .download(serversWithSizes):
            download(track: track, from: serversWithSizes)
        case let .completeDownloadFromServer(serverId, _):
            downloadManager.download(track, from: serverId)
        case .cancelDownload, .deleteDownloaded:
            downloadManager.cancelDownload(track)
        case .markAsListened:
            DataStorage.writer.set(fullyListened: true, forTrack: track)
        case .markAsNotListened:
            DataStorage.writer.set(fullyListened: false, forTrack: track)
        }
    }

    #if DEBUG
    // unit-tests only
    internal func waitForTheBackgroundQueue() {
        BackgroundQueue.sync { }
    }
    #endif
}
