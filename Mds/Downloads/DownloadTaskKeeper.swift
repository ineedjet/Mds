import Foundation

protocol DownloadTaskKeeperDelegate: AnyObject {
    func taskKeeper(didUpdateCachingStateOfRecordWithId recordId: RecordId, to newState: RecordCachingState)
}

class DownloadTaskKeeper {
    private var dataReader: DataReader
    private var downloading: [(RecordId,URLSessionDownloadTask,Progress)] = []

    weak var delegate: DownloadTaskKeeperDelegate?

    init(dataReader: DataReader = DataStorage.reader) {
        self.dataReader = dataReader
    }

    private func createProgress(for task: URLSessionDownloadTask) -> Progress {
        if #available(iOS 11.0, *) {
            return task.progress
        } else {
            let totalBytes = task.countOfBytesExpectedToReceive
            let doneBytes = task.countOfBytesReceived
            let p = Progress(totalUnitCount: totalBytes)
            p.completedUnitCount = doneBytes
            return p
        }
    }

    private func findOrCreate(task: URLSessionDownloadTask, forRecord r: MdsRecord? = nil) -> Int? {
        if let idx = downloading.firstIndex(where: {$0.1.taskIdentifier == task.taskIdentifier}) {
            return idx
        }
        let record: MdsRecord
        if let r = r {
            record = r
        }
        else if let url = task.originalRequest?.url,
            let r = dataReader.tryGetRecord(withUrl: url) {
            record = r
        }
        else {
            return nil
        }
        let progress = createProgress(for: task)
        downloading.append((record.recordId, task, progress))
        delegate?.taskKeeper(didUpdateCachingStateOfRecordWithId: record.recordId, to: .caching(progress))
        return downloading.count - 1
    }

    func add(task: URLSessionDownloadTask, forRecord record: MdsRecord? = nil) {
        _ = findOrCreate(task: task, forRecord: record)
    }

    func find(taskByRecordId recordId: RecordId) -> URLSessionDownloadTask? {
        return downloading.first{$0.0 == recordId}?.1
    }

    func update(task: URLSessionDownloadTask, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard #available(iOS 11.0, *) else {
            guard let idx = findOrCreate(task: task) else {
                print("Something updated progress, but can't figure out which record")
                return
            }
            let p = downloading[idx].2
            p.totalUnitCount = totalBytesExpectedToWrite
            p.completedUnitCount = totalBytesWritten
            return
        }
        // no action is required for iOS 11.0
    }

    func remove(task: URLSessionDownloadTask) -> RecordId? {
        guard let idx = findOrCreate(task: task) else {
            return nil
        }
        let recordId = downloading[idx].0
        downloading.remove(at: idx)
        return recordId
    }
}
