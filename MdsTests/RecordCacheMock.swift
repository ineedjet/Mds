@testable import Mds

class RecordCacheMock : RecordCache {
    private let strict: Bool

    init(strict: Bool) {
        self.strict = strict
    }

    private var cacheDelegate = [RecordId:() -> Void]()
    func setUp(cacheRecord record: MdsRecord, action: @escaping () -> Void) {
        cacheDelegate[record.recordId] = action
    }
    func cache(record: MdsRecord) {
        if let del = cacheDelegate[record.recordId] {
            del()
        }
        else if self.strict {
            fatalError("Unmocked call - cache(record: \(record.recordId))")
        }
    }

    private(set) var backgroundCompletionHandler: (() -> Void)? = nil
    func setBackgroundCompletionHandler(_ completionHandler: @escaping () -> Void) {
        backgroundCompletionHandler = completionHandler
    }

    private var deleteDelegate = [RecordId:() -> Void]()
    func setUp(deleteRecordWithId recordId: RecordId, action: @escaping () -> Void) {
        deleteDelegate[recordId] = action
    }
    func delete(recordWithId recordId: RecordId) {
        if let del = deleteDelegate[recordId] {
            del()
        }
        else if self.strict {
            fatalError("Unmocked call - delete(record: \(recordId))")
        }
    }

    private(set) var estimateSizeRequests: [(MdsRecord, (Int64?) -> Void)] = []
    func estimateSize(ofRecord record: MdsRecord, callback: @escaping (Int64?) -> Void) {
        estimateSizeRequests.append((record, callback))
    }
}
