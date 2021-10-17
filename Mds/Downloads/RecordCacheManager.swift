import Foundation

let DownloadManagerBackgroundURLSessionIdentifier: String = "net.samarkin.Mds.DownloadManager"

fileprivate let MigrationQueue = DispatchQueue(label: "net.samarkin.Mds.RecordCacheManager.MigrationQueue")

fileprivate extension URL {
    var contentModificationDate: Date? { return try? self.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate }
}

final class RecordCacheManager: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDownloadDelegate, DownloadTaskKeeperDelegate, RecordCache {

    private let intermittentCacheDir: URL
    private var persistentCacheDir: URL
    private var urlSession: URLSession!
    private var backgroundCompletionHandler: (() -> Void)?
    private var fileManager: FileManager

    private var backUpDownloadsObservation: NSKeyValueObservation!
    private var backUpDownloads: Bool { return UserDefaults.standard.backUpDownloads }
    private var currentCacheDir: URL { return persistentCacheDir }
    private var isMigrating: Bool = false {
        didSet {
            notifyDelegate { $0.recordCache(self, didUpdateMigrationStatus: isMigrating) }
        }
    }

    private let taskKeeper: DownloadTaskKeeper

    weak private(set) var delegate: RecordCacheDelegate?
    private(set) var delegateQueue: DispatchQueue?

    internal init(delegate: RecordCacheDelegate?, delegateQueue: DispatchQueue?, fileManager: FileManager = .default) {
        self.delegate = delegate
        self.delegateQueue = delegateQueue
        self.fileManager = fileManager
        intermittentCacheDir = try! fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        persistentCacheDir = try! fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("Downloads")
        try! fileManager.createDirectory(at: persistentCacheDir, withIntermediateDirectories: true)
        RecordCacheManager.setBackup(enabled: UserDefaults.standard.backUpDownloads, forURL: &persistentCacheDir)
        taskKeeper = DownloadTaskKeeper()

        let config = URLSessionConfiguration.background(withIdentifier: DownloadManagerBackgroundURLSessionIdentifier)
        config.isDiscretionary = false // only affects downloads started in foreground
        config.sessionSendsLaunchEvents = true
        super.init()
        taskKeeper.delegate = self
        reportDownloadedFiles()
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
        urlSession.getTasksWithCompletionHandler { (_,_,downloadTasks) in
            if downloadTasks.count > 0 {
                for task in downloadTasks {
                    self.taskKeeper.add(task: task)
                }
            }
        }

        backUpDownloadsObservation = UserDefaults.standard.observe(\.backUpDownloads) { [weak self] (_,_) in
            if let self = self {
                RecordCacheManager.setBackup(enabled: self.backUpDownloads, forURL: &self.persistentCacheDir)
            }
        }
        scheduleMigration(from: intermittentCacheDir, to: persistentCacheDir)
    }

    private func reportDownloadedFiles() {
        let contents: [URL]
        do {
            contents = try fileManager.contentsOfDirectory(
                at: currentCacheDir,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles).sorted {
                guard let leftDate = $0.contentModificationDate,
                    let rightDate = $1.contentModificationDate
                    else {
                    return false // we don't care about the order in this case
                }
                return leftDate < rightDate
            }
        }
        catch {
            print("Failed to get contents of the cache directory \(currentCacheDir.path): \(error)")
            return
        }
        for url in contents.filter({$0.pathExtension == "mp3"}) {
            if let recordId = RecordId(url.deletingPathExtension().lastPathComponent),
                let fileSize = getFileSize(atPath: url.path) {
                notifyUpdateCachingState(ofRecordWithId: recordId, to: .cached(url, fileSize))
            }
        }
    }

    private func notifyDelegate(call: (RecordCacheDelegate) -> Void) {
        guard let delegate = self.delegate else {
            return
        }
        (delegateQueue ?? DispatchQueue.main).sync {
            call(delegate)
        }
    }

    private func notifyUpdateCachingState(ofRecordWithId recordId: RecordId, to newState: RecordCachingState) {
        notifyDelegate { $0.recordCache(self, didUpdateCachingStateOfRecordWithId: recordId, to: newState) }
    }

    func taskKeeper(didUpdateCachingStateOfRecordWithId recordId: RecordId, to newState: RecordCachingState) {
        notifyUpdateCachingState(ofRecordWithId: recordId, to: newState)
    }

    private static func setBackup(enabled value: Bool, forURL url: inout URL) {
        do {
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = !value
            try url.setResourceValues(resourceValues)
        }
        catch {
            print("Failed to set resource value for \(url.path)")
        }
    }

    private func scheduleMigration(from: URL, to: URL) {
        MigrationQueue.async {
            let contents: [URL]
            do {
                contents = try self.fileManager.contentsOfDirectory(at: from, includingPropertiesForKeys: nil, options: .skipsHiddenFiles).filter{$0.pathExtension == "mp3"}
            }
            catch {
                print("Failed to get contents of the cache directory \(from.path): \(error)")
                return
            }

            print("Preparing to migrate \(contents.count) items...")
            guard contents.count > 0 else {
                return
            }
            DispatchQueue.main.sync {
                self.isMigrating = true
            }
            defer {
                DispatchQueue.main.async {
                    print("Migration complete")
                    self.isMigrating = false
                }
            }

            for file in contents {
                do {
                    let newLocation = to.appendingPathComponent(file.lastPathComponent)
                    try self.fileManager.moveItem(at: file, to: newLocation)
                    if let recordId = RecordId(file.lastPathComponent.dropLast(4)),
                        let fileSize = self.getFileSize(atPath: newLocation.path) {
                        self.notifyUpdateCachingState(ofRecordWithId: recordId, to: .cached(newLocation, fileSize))
                    }
                }
                catch {
                    print("Failed to move item \(file.absoluteString)")
                }
            }
        }
    }

    private func getCachedUrl(forRecordId recordId: RecordId) -> URL {
        return currentCacheDir.appendingPathComponent("\(recordId).mp3")
    }

    func cache(record: MdsRecord) {
        guard taskKeeper.find(taskByRecordId: record.recordId) == nil,
            !fileManager.fileExists(atPath: getCachedUrl(forRecordId: record.recordId).path) else {
            print("Attempt to cache record \(record.recordId) twice")
            return
        }
        let task = urlSession.downloadTask(with: record.url)
        taskKeeper.add(task: task, forRecord: record)
        task.resume()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        taskKeeper.update(task: downloadTask,
                          totalBytesWritten: totalBytesWritten,
                          totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let recordId = taskKeeper.remove(task: downloadTask) else {
            print("Something finished downloading, but can't figure out which record")
            return
        }
        let cachedUrl = getCachedUrl(forRecordId: recordId)
        do {
            try fileManager.moveItem(at: location, to: cachedUrl)
        }
        catch {
            print("Failed to move downloaded file: \(error)")
        }
        // at this point, task is deleted already - we need to report it
        let newState: RecordCachingState
        if let fileSize = getFileSize(atPath: cachedUrl.path) {
            newState = .cached(cachedUrl, fileSize)
        }
        else {
            newState = .notCached
        }
        notifyUpdateCachingState(ofRecordWithId: recordId, to: newState)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else {
            return
        }
        guard let task = task as? URLSessionDownloadTask, let recordId = taskKeeper.remove(task: task) else {
            print("Something failed to finish, but can't figure out which record")
            return
        }
        if (error as NSError).domain != NSURLErrorDomain || (error as NSError).code != NSURLErrorCancelled {
            let trackName = task.originalRequest?.url?.absoluteString ?? "Record \(recordId)"
            print("Failed to download \(trackName): \(error)")
            notifyDelegate { $0.recordCache(self, didReportError: error) }
        }

        // at this point, task is deleted already - we need to report it
        let cachedUrl = getCachedUrl(forRecordId: recordId)
        let newState: RecordCachingState
        if let fileSize = getFileSize(atPath: cachedUrl.path) {
            newState = .cached(cachedUrl, fileSize)
        }
        else {
            newState = .notCached
        }
        notifyUpdateCachingState(ofRecordWithId: recordId, to: newState)
    }

    func setBackgroundCompletionHandler(_ completionHandler: @escaping () -> Void) {
        self.backgroundCompletionHandler = completionHandler
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        let completionHandler = self.backgroundCompletionHandler
        DispatchQueue.main.async {
            completionHandler?()
        }
    }

    func estimateSize(ofRecord record: MdsRecord, callback: @escaping (Int64?) -> Void) {
        var request = URLRequest(url: record.url)
        request.httpMethod = "HEAD"
        // use a non-background "shared" session here
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil,
                let response = response as? HTTPURLResponse,
                let lengthString = response.allHeaderFields[AnyHashable("Content-Length")] as? String,
                let length = Int64(lengthString)
                else {
                callback(nil)
                return
            }
            callback(length)
        }.resume()
    }

    private func getFileSize(atPath path: String) -> Int64? {
        let attr = try? fileManager.attributesOfItem(atPath: path)
        let sizeNumber = attr?[.size] as? NSNumber
        return sizeNumber?.int64Value
    }

    func delete(recordWithId recordId: RecordId) {
        if let task = taskKeeper.find(taskByRecordId: recordId) {
            print("Download in progress - cancelling...")
            task.cancel()
            notifyUpdateCachingState(ofRecordWithId: recordId, to: .notCached)
        }
        else {
            print("Download already finished - deleting file...")
            let cachedUrl = getCachedUrl(forRecordId: recordId)
            do {
                try fileManager.removeItem(at: cachedUrl)
                notifyUpdateCachingState(ofRecordWithId: recordId, to: .notCached)
            }
            catch {
                print("Failed to remove file \(cachedUrl.path): \(error)")
            }
        }
    }
}
