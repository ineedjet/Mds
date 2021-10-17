import Foundation

enum RecordCachingState {
    case notCached
    case caching(Progress)
    case cached(URL, Int64)
}

protocol RecordCacheDelegate : AnyObject {
    func recordCache(_ cache: RecordCache, didUpdateMigrationStatus isMigrating: Bool)
    func recordCache(_ cache: RecordCache, didUpdateCachingStateOfRecordWithId recordId: RecordId, to newState: RecordCachingState)
    func recordCache(_ cache: RecordCache, didReportError error: Error)
}

protocol RecordCache {
    func estimateSize(ofRecord record: MdsRecord, callback: @escaping (Int64?) -> Void)
    func cache(record: MdsRecord)
    func setBackgroundCompletionHandler(_ completionHandler: @escaping () -> Void)
    func delete(recordWithId recordId: RecordId)
}
