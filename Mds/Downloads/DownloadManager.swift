import Foundation

extension Notification.Name {
    static let downloadManagerDidUpdateCache = Notification.Name(rawValue: "DownloadManagerDidUpdateCache")
    static let downloadManagerDidUpdateMigrationStatus = Notification.Name(rawValue: "DownloadManagerDidUpdateMigrationStatus")
    static let downloadManagerDidReportError = Notification.Name(rawValue: "DownloadManagerDidReportError")
}

let DownloadManagerTrackKey: String = "DownloadManagerTrack"
let DownloadManagerErrorKey: String = "DownloadManagerError"
fileprivate let StateUpdateQueue = DispatchQueue(label: "net.samarkin.Mds.DownloadManager.StateUpdateQueue")
fileprivate let SizeEstimationQueue = DispatchQueue(label: "net.samarkin.Mds.DownloadManager.SizeEstimationQueue")

enum DownloadState {
    case notDownloaded
    case preparing
    case downloading(ServerId, Progress)
    case incomplete(ServerId, Progress)
    case corrupted(Int64)
    case downloaded(ServerId, Int64)
}

struct DownloadItem {
    let trackId: TrackId
    let state: DownloadState
}

class DownloadManager: RecordCacheDelegate {
    static let shared = DownloadManager()
    private var cache: RecordCache! // can be nil when accessed from delegate callbacks
    private let dataReader: DataReader

    private var recordStates: [RecordId:RecordCachingState] = [:]
    private var trackOrder: [TrackId] = []
    private var trackStatesCache: [TrackId: DownloadState] = [:]
    private var trackProgresses: [TrackId: [ServerId:Progress]] = [:]
#if DEBUG
    // unit-tests only
    private(set) var preparedForDownload: Set<TrackId> = []
#else
    private var preparedForDownload: Set<TrackId> = []
#endif

    private(set) var isMigrating: Bool = false {
        didSet {
            NotificationCenter.default.post(name: .downloadManagerDidUpdateMigrationStatus, object: self)
        }
    }

    private init() {
        self.dataReader = DataStorage.reader
        self.cache = RecordCacheManager(delegate: self, delegateQueue: StateUpdateQueue)
    }

#if DEBUG
    // unit-tests only
    internal init(recordCache: RecordCache, dataReader: DataReader) {
        self.dataReader = dataReader
        self.cache = recordCache
    }
#endif

    func download(_ track: MdsTrack, from serverId: ServerId, onlyIfPrepared: Bool = false) {
        let wasPrepared = StateUpdateQueue.sync { preparedForDownload.remove(track.trackId) } != nil
        guard !onlyIfPrepared || wasPrepared else {
            return
        }
        for record in track.getRecords(serverId) {
            cache.cache(record: record)
        }
        if wasPrepared {
            StateUpdateQueue.sync { notifyCacheUpdated(forTrack: track) }
        }
    }

    func prepareDownload(ofTrack track: MdsTrack) {
        StateUpdateQueue.sync {
            let becamePrepared = preparedForDownload.insert(track.trackId).0
            if becamePrepared {
                notifyCacheUpdated(forTrack: track)
            }
        }
    }

    func cancelPreparation(ofTrack track: MdsTrack, becauseOf error: Error? = nil) {
        StateUpdateQueue.sync {
            if preparedForDownload.remove(track.trackId) != nil {
                notifyCacheUpdated(forTrack: track)
                if let error = error {
                    report(error: error)
                }
            }
        }
    }

    func estimateSize(ofTrack track: MdsTrack, fromServer server: ServerId, callback: @escaping (Int64?) -> Void) {
        var count = 0
        var totalSize: Int64 = 0
        let allRecords = track.getRecords(server)
        let allRecordsCount = allRecords.count
        for record in allRecords {
            cache.estimateSize(ofRecord: record) { optionalSize in
                var shouldCall = false
                var sizeToReport: Int64? = nil
                SizeEstimationQueue.sync {
                    guard count >= 0 else {
                        // already failed
                        return
                    }
                    guard let recordSize = optionalSize else {
                        // failed for the first time
                        count = -1
                        shouldCall = true
                        return
                    }
                    count += 1
                    totalSize += recordSize
                    if count == allRecordsCount {
                        shouldCall = true
                        sizeToReport = totalSize
                    }
                }
                if shouldCall {
                    callback(sizeToReport)
                }
            }
        }
    }

    func setBackgroundCompletionHandler(_ completionHandler: @escaping () -> Void) {
        cache.setBackgroundCompletionHandler(completionHandler)
    }

    private func getOrCreateTrackProgress(forTrack track: MdsTrack, andServer serverId: ServerId) -> Progress {
        if trackProgresses[track.trackId] == nil {
            trackOrder.append(track.trackId)
            trackProgresses[track.trackId] = [:]
        }
        if let p = trackProgresses[track.trackId]![serverId] {
            return p
        }
        let totalSize = track.getRecords(serverId).reduce(0) {$0 + $1.fileSize}
        let result = Progress(totalUnitCount: totalSize)
        trackProgresses[track.trackId]![serverId] = result
        return result
    }

    private func trim(track: MdsTrack) {
        let hasAnyRecords = track.allRecords.reduce(false) { $0 || recordStates[$1.recordId] != nil }
        if !hasAnyRecords {
            trackProgresses.removeValue(forKey: track.trackId)
            trackOrder.removeAll { $0 == track.trackId }
        }
    }

    func recordCache(_ cache: RecordCache, didUpdateCachingStateOfRecordWithId recordId: RecordId, to newState: RecordCachingState) {
        guard let record = dataReader.tryGetRecord(withId: recordId), let track = record.mdsTrack else {
            // we don't care about a record if it's not part of some track
            // let's delete it later
            DispatchQueue.main.async {
                // FIXME: Successful deletion will trigger didUpdateCachingStateOfRecordWithId one more time
                cache.delete(recordWithId: recordId)
            }
            return
        }
        let serverId = record.server
        let oldState = recordStates[recordId, default: .notCached]
        recordStates[recordId] = newState
        switch oldState {
        case .notCached:
            switch newState {
            case .notCached:
                // nothing to do here
                break
            case let .caching(progress):
                let trackProgress = getOrCreateTrackProgress(forTrack: track, andServer: serverId)
                trackProgress.addChild(progress, withPendingUnitCount: record.fileSize)
                notifyCacheUpdated(forTrack: track)
                break
            case .cached:
                let trackProgress = getOrCreateTrackProgress(forTrack: track, andServer: serverId)
                trackProgress.completedUnitCount += record.fileSize
                notifyCacheUpdated(forTrack: track)
                break
            }
        case let .caching(progress):
            switch newState {
            case .notCached:
                // cancelled
                progress.completedUnitCount = 0
                recordStates.removeValue(forKey: recordId)
                trim(track: track)
                notifyCacheUpdated(forTrack: track)
                break
            case let .caching(newProgress):
                // nothing to do here
                assert(progress == newProgress, "Progresses vary")
                break
            case .cached:
                // finished
                progress.completedUnitCount = progress.totalUnitCount // make sure isFinished is set
                notifyCacheUpdated(forTrack: track)
                break
            }
        case let .cached(url, fileSize):
            switch newState {
            case .notCached:
                let trackProgress = getOrCreateTrackProgress(forTrack: track, andServer: serverId)
                trackProgress.completedUnitCount -= record.fileSize
                recordStates.removeValue(forKey: recordId)
                trim(track: track)
                notifyCacheUpdated(forTrack: track)
                break
            case let .caching(progress):
                // there is no good use-case for this, but let's implement it anyway
                let trackProgress = getOrCreateTrackProgress(forTrack: track, andServer: serverId)
                trackProgress.completedUnitCount -= record.fileSize
                trackProgress.addChild(progress, withPendingUnitCount: record.fileSize)
                notifyCacheUpdated(forTrack: track)
                break
            case let .cached(newUrl, newFileSize):
                // nothing to do here
                assert(url == newUrl, "URLs vary")
                assert(fileSize == newFileSize, "File sizes vary")
                break
            }
        }
    }

    // always called on StateUpdateQueue
    private func notifyCacheUpdated(forTrack track: MdsTrack) {
        trackStatesCache.removeValue(forKey: track.trackId)
        // TODO: Block notifications for long operations
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .downloadManagerDidUpdateCache, object: self, userInfo: [
                DownloadManagerTrackKey: track
            ])
        }
    }

    // always called on StateUpdateQueue
    private func report(error: Error) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .downloadManagerDidReportError, object: self, userInfo: [
                DownloadManagerErrorKey: error
            ])
        }
    }

    func recordCache(_ cache: RecordCache, didUpdateMigrationStatus isMigrating: Bool) {
        DispatchQueue.main.async {
            self.isMigrating = isMigrating
        }
    }

    func recordCache(_ cache: RecordCache, didReportError error: Error) {
        report(error: error)
    }

    private func getDownloadStateInternal(_ track: MdsTrack) -> DownloadState {
        if let cachedState = trackStatesCache[track.trackId] {
            return cachedState
        }
        var server: ServerId? = nil
        var corrupted = false
        var totalFiles = 0
        var totalSize: Int64 = 0
        var inProgress = false
        for record in track.allRecords.sorted(by: {$0.partNumber < $1.partNumber}) {
            switch recordStates[record.recordId, default: .notCached] {
            case let .cached(_, fileSize):
                if let currentServer = server, currentServer != record.server {
                    corrupted = true
                }
                server = record.server
                totalFiles += 1
                totalSize += fileSize
            case .caching:
                if let currentServer = server, currentServer != record.server {
                    corrupted = true
                }
                server = record.server
                inProgress = true
            case .notCached:
                // skipping
                break
            }
        }
        let state: DownloadState
        if corrupted {
            state = .corrupted(totalSize)
        }
        else if let serverId = server {
            let allRecords = track.getRecords(serverId)
            if totalFiles == allRecords.count {
                state = .downloaded(serverId, totalSize)
            }
            else {
                let progress = getOrCreateTrackProgress(forTrack: track, andServer: serverId)
                state = inProgress ? .downloading(serverId, progress) : .incomplete(serverId, progress)
            }
        }
        else {
            // no records found
            state = .notDownloaded
        }
        trackStatesCache[track.trackId] = state
        return state
    }

    func getCachedUrl(ofRecord record: MdsRecord) -> URL? {
        if case .cached(let url, _) = recordStates[record.recordId, default: .notCached] {
            return url
        }
        return nil
    }

    func getDownloadState(_ track: MdsTrack) -> DownloadState {
        return StateUpdateQueue.sync {
            preparedForDownload.contains(track.trackId)
                ? .preparing
                : getDownloadStateInternal(track)
        }
    }

    func cancelDownload(_ track: MdsTrack) {
        StateUpdateQueue.sync {
            if preparedForDownload.remove(track.trackId) != nil {
                notifyCacheUpdated(forTrack: track)
            }
        }
        for record in track.allRecords {
            cache.delete(recordWithId: record.recordId)
        }
    }

    func getDownloads() -> [DownloadItem] {
        return StateUpdateQueue.sync {
            var result: [DownloadItem] = []
            for trackId in preparedForDownload {
                result.append(DownloadItem(trackId: trackId, state: .preparing))
            }
            for trackId in trackOrder.reversed() {
                if let track = dataReader.tryGetTrack(withId: trackId) {
                    result.append(DownloadItem(trackId: trackId, state: self.getDownloadStateInternal(track)))
                }
            }
            return result
        }
    }
}
