class RecentsController: TrackListControllerBase {
    override var headerField: HeaderField { .lastListened }

    override func getData() -> [MdsTrack] {
        return DataStorage.reader.getAllTrackListenInfos().sorted{$0.lastListened > $1.lastListened}.map{$0.track!}
    }

    override func getSectionifyFunc() -> (MdsTrack) -> String? {
        return { $0.lastListened?.mnemonicIntervalString ?? "Неизвестно" }
    }

    override func dataStorage(didUpdate properties: DataStorageTrackProperties, of track: MdsTrack) {
        // TODO: optimize
        refreshDataAndNotifyDelegate(changeType: .drasticChange)
    }
}
