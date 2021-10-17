import MediaPlayer

final class RemoteCommandCenter: NSObject {
    private let cmdCenter = MPRemoteCommandCenter.shared()
    private var cmdCenterToken: [MPRemoteCommand: Any] = [:]
    private weak var audioPlayer: AudioPlayer?

    init(for audioPlayer: AudioPlayer) {
        super.init()
        self.audioPlayer = audioPlayer
        cmdCenterToken[cmdCenter.playCommand] = cmdCenter.playCommand.addTarget(self, action: #selector(play))
        cmdCenterToken[cmdCenter.pauseCommand] = cmdCenter.pauseCommand.addTarget(self, action: #selector(pause))
        cmdCenterToken[cmdCenter.togglePlayPauseCommand] = cmdCenter.togglePlayPauseCommand.addTarget(self, action: #selector(playPause))
        cmdCenter.nextTrackCommand.isEnabled = false
        cmdCenter.previousTrackCommand.isEnabled = false
        cmdCenter.changeRepeatModeCommand.isEnabled = false
        cmdCenter.changeShuffleModeCommand.isEnabled = false
        cmdCenterToken[cmdCenter.skipForwardCommand] = cmdCenter.skipForwardCommand.addTarget(self, action: #selector(skipForward))
        cmdCenterToken[cmdCenter.skipBackwardCommand] = cmdCenter.skipBackwardCommand.addTarget(self, action: #selector(skipBackward))
        cmdCenterToken[cmdCenter.changePlaybackPositionCommand] = cmdCenter.changePlaybackPositionCommand.addTarget(self, action: #selector(setPosition))
    }

    deinit {
        for (cmd, token) in cmdCenterToken {
            cmd.removeTarget(token)
        }
    }

    @objc private func play(_ ev: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return executeIfPlayerIsReady { audioPlayer in
            audioPlayer.play()
            return .success
        }
    }

    @objc private func playPause(_ ev: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return executeIfPlayerIsReady { audioPlayer in
            switch audioPlayer.state {
            case .playing:
                audioPlayer.pause()
                return .success
            case .paused, .selected:
                audioPlayer.play()
                return .success
            case .idle, .error, .preparing, .loading:
                return .commandFailed
            }
        }
    }

    @objc private func pause(_ ev: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return executeIfPlayerIsReady { audioPlayer in
            audioPlayer.pause()
            return .success
        }
    }

    @objc private func skipForward(_ ev: MPSkipIntervalCommandEvent) -> MPRemoteCommandHandlerStatus {
        return executeIfPlayerIsReady { audioPlayer in
            audioPlayer.skip(ev.interval)
            return .success
        }
    }

    @objc private func skipBackward(_ ev: MPSkipIntervalCommandEvent) -> MPRemoteCommandHandlerStatus {
        return executeIfPlayerIsReady { audioPlayer in
            audioPlayer.skip(-ev.interval)
            return .success
        }
    }

    @objc private func setPosition(_ ev: MPChangePlaybackPositionCommandEvent) -> MPRemoteCommandHandlerStatus {
        return executeIfPlayerIsReady { audioPlayer in
            audioPlayer.setPosition(ev.positionTime)
            return .success
        }
    }

    private func executeIfPlayerIsReady(action: (AudioPlayer) -> MPRemoteCommandHandlerStatus) -> MPRemoteCommandHandlerStatus {
        guard let audioPlayer = audioPlayer else {
            return .noActionableNowPlayingItem
        }
        switch audioPlayer.state {
        case .idle, .error:
            return .noActionableNowPlayingItem
        case .preparing, .loading, .selected:
            return .commandFailed
        case .playing, .paused:
            return action(audioPlayer)
        }
    }
}
