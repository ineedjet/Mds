import CoreData

fileprivate var trackCache: [TrackId:MdsTrackMO]?

extension DataStorage {
    func getAllTracks() -> [MdsTrack] {
        return Array(getTrackCache().values)
    }

    fileprivate func getTrackCache() -> [TrackId:MdsTrackMO] {
        if let trackCache = trackCache {
            return trackCache
        }
        let moc = readonlyContainer.viewContext
        let fetchTracks = NSFetchRequest<MdsTrackMO>(entityName: "MdsTrack")
        let allTracks: [MdsTrackMO]
        do {
            allTracks = try moc.fetch(fetchTracks)
        }
        catch {
            fatalError("Failed to fetch tracks: \(error)")
        }
        var cache: [TrackId:MdsTrackMO] = [:]
        for track in allTracks {
            cache[track.trackId] = track
        }
        trackCache = cache
        return cache
    }

    func getTotalTrackCount() -> Int {
        return getTrackCache().values.count
    }

    static func invalidateTrackCache() {
        trackCache = nil
    }

    func tryGetTrack(withId id: TrackId) -> MdsTrack? {
        return getTrackCache()[id]
    }

    func tryGetRecord(withId id: RecordId) -> MdsRecord? {
        let moc = readonlyContainer.viewContext
        let fetchRecord = NSFetchRequest<MdsRecordMO>(entityName: "MdsRecord")
        fetchRecord.predicate = NSPredicate(format: "recordId == %@", NSNumber(value: id))
        return (try? moc.fetch(fetchRecord))?.first
    }

    func tryGetRecord(withUrl url: URL) -> MdsRecord? {
        let moc = readonlyContainer.viewContext
        let fetchRecord = NSFetchRequest<MdsRecordMO>(entityName: "MdsRecord")
        fetchRecord.predicate = NSPredicate(format: "urlString == %@", url.absoluteString)
        return (try? moc.fetch(fetchRecord))?.first
    }
}
