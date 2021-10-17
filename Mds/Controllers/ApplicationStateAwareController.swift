import Foundation

protocol ApplicationStateAwareControllerDelegate: AnyControllerDelegate {
    func controllerDidUpdatePlayerState(_ controller: AnyController)
    func controllerDidReceiveNewPlayerPosition(_ controller: AnyController)
    func controllerDidReceiveNewPlayerDuration(_ controller: AnyController)
    func controllerDidReceiveNewSleepTimerValue(_ controller: AnyController)
}

class ApplicationStateAwareController: AnyController {
    private weak var applicationStateAwareDelegate: ApplicationStateAwareControllerDelegate? {
        return delegate as? ApplicationStateAwareControllerDelegate
    }

    let audioPlayer: AudioPlayer
    let downloadManager: DownloadManager

    var playerState: AudioPlayerState { return audioPlayer.state }
    var playerPosition: Double {
        get { return audioPlayer.position }
        set { audioPlayer.setPosition(newValue) }
    }
    var sleepTimer: TimeInterval? { return audioPlayer.sleepTimer }
    var playerDuration: Double { return audioPlayer.duration }
    var isMigrating: Bool { return downloadManager.isMigrating }

    init(audioPlayer: AudioPlayer = RealAudioPlayer.shared, downloadManager: DownloadManager = .shared) {
        self.audioPlayer = audioPlayer
        self.downloadManager = downloadManager
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(audioPlayerDidChangeState(_:)), name: .audioPlayerDidChangeState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(audioPlayerDidUpdatePosition), name: .audioPlayerDidUpdatePosition, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(audioPlayerDidUpdateDuration), name: .audioPlayerDidUpdateDuration, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(audioPlayerDidUpdateSleepTimer), name: .audioPlayerDidUpdateSleepTimer, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadManagerDidReportError), name: .downloadManagerDidReportError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(migrationStatusChanged), name: .downloadManagerDidUpdateMigrationStatus, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func playCurrent() {
        audioPlayer.play()
    }

    func pauseCurrent() {
        audioPlayer.pause()
    }

    func getDownloadState(of track: MdsTrack) -> DownloadState {
        return downloadManager.getDownloadState(track)
    }

    @objc private func audioPlayerDidChangeState(_ notification: Notification) {
        if case let .error(error) = playerState {
            delegate?.controller(self, didReportError: error)
        }
        applicationStateAwareDelegate?.controllerDidUpdatePlayerState(self)
        audioPlayerDidChangeState(from: notification.userInfo?[AudioPlayerPreviousStateKey] as? AudioPlayerState)
    }

    func audioPlayerDidChangeState(from oldState: AudioPlayerState?) {
        // virtual method
    }

    @objc private func audioPlayerDidUpdatePosition(_ notification: Notification) {
        applicationStateAwareDelegate?.controllerDidReceiveNewPlayerPosition(self)
    }

    @objc private func audioPlayerDidUpdateDuration(_ notification: Notification) {
        applicationStateAwareDelegate?.controllerDidReceiveNewPlayerDuration(self)
    }

    @objc private func audioPlayerDidUpdateSleepTimer() {
        applicationStateAwareDelegate?.controllerDidReceiveNewSleepTimerValue(self)
    }

    @objc private func downloadManagerDidReportError(_ notification: NSNotification) {
        guard let error = notification.userInfo?[DownloadManagerErrorKey] as? Error else {
            print("Error is reported, but the error information is missing")
            return
        }
        delegate?.controller(self, didReportError: error)
    }

    @objc private func migrationStatusChanged() {
        delegate?.controllerDidUpdateMigrationStatus(self)
    }
}
