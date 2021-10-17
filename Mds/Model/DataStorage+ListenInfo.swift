import CoreData

fileprivate var listenInfoCache: [TrackId: MdsTrackListenInfoMO]?

extension DataStorage {
    func getAllTrackListenInfos() -> [MdsTrackListenInfo] {
        return Array(getListenInfoCache().values)
    }

    fileprivate func insertMdsTrackListenInfo(forTrack trackId: TrackId) -> MdsTrackListenInfoMO {
        guard let moc = metadataContainer?.viewContext else {
            fatalError("No writable container found")
        }
        let result = NSEntityDescription.insertNewObject(forEntityName: "MdsTrackListenInfo", into: moc) as! MdsTrackListenInfoMO
        result.trackId = trackId
        listenInfoCache?[trackId] = result
        return result
    }

    fileprivate func getListenInfoCache() -> [TrackId:MdsTrackListenInfoMO] {
        if let listenInfoCache = listenInfoCache {
            return listenInfoCache
        }
        guard let moc = metadataContainer?.viewContext else {
            fatalError("No writable container found")
        }
        let fetchInfo = NSFetchRequest<MdsTrackListenInfoMO>(entityName: "MdsTrackListenInfo")
        let allInfos: [MdsTrackListenInfoMO]
        do {
            allInfos = try moc.fetch(fetchInfo)
        }
        catch {
            fatalError("Failed to fetch listen infos: \(error)")
        }
        var x: [TrackId:MdsTrackListenInfoMO] = [:]
        for i in allInfos {
            x[i.trackId] = i
        }
        listenInfoCache = x
        return x
    }

    static func invalidateListenInfoCache() {
        listenInfoCache = nil
    }

    func getUnfinishedTracks()  -> [MdsTrack] {
        let cache = getListenInfoCache()
        return getAllTracks().filter{cache[$0.trackId]?.fullyListened != true}
    }

    fileprivate func save() {
        if let context = metadataContainer?.viewContext, context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func tryGetTrackListenInfo(forTrack trackId: TrackId) -> MdsTrackListenInfo? {
        return getListenInfoCache()[trackId]
    }

    func getOrCreateTrackListenInfo(forTrack trackId: TrackId) -> MdsTrackListenInfo {
        return getListenInfoCache()[trackId] ?? insertMdsTrackListenInfo(forTrack: trackId)
    }

    fileprivate func getOrCreateTrackListenInfoMO(forTrack trackId: TrackId) -> MdsTrackListenInfoMO {
        return getListenInfoCache()[trackId] ?? insertMdsTrackListenInfo(forTrack: trackId)
    }

    func getLastTrack() -> (MdsTrack, ServerId)? {
        guard let lastInfo = getListenInfoCache().values.sorted(by:{$0.lastListened > $1.lastListened}).first,
              let track = lastInfo.track,
              let serverId = ServerId(rawValue: lastInfo.lastServerId) else {
            return nil
        }
        return (track, serverId)
    }

    fileprivate func notify(ofChanging properties: DataStorageTrackProperties, of track: MdsTrack) {
        NotificationCenter.default.post(name: .dataStorageDidUpdateTrack,
                                        object: self,
                                        userInfo: [
                                            DataStorageTrackKey: track,
                                            DataStoragePropertiesKey: properties,
                                        ])
    }

    func set(lastListened: Date, forTrack track: MdsTrack) {
        let listenInfo = getOrCreateTrackListenInfoMO(forTrack: track.trackId)
        listenInfo.lastListened = lastListened
        save()
        notify(ofChanging: [.lastListened], of: track)
    }

    func set(lastPosition: Double, forTrack track: MdsTrack) {
       let listenInfo = getOrCreateTrackListenInfoMO(forTrack: track.trackId)
       listenInfo.lastPosition = lastPosition
       save()
       notify(ofChanging: [.lastPosition], of: track)
   }

    func set(lastPosition: Double, lastServerId: ServerId, forTrack track: MdsTrack) {
        let listenInfo = getOrCreateTrackListenInfoMO(forTrack: track.trackId)
        listenInfo.lastPosition = lastPosition
        listenInfo.lastServerId = lastServerId.rawValue
        save()
        notify(ofChanging: [.lastPosition, .lastServerId], of: track)
    }

    func set(fullyListened: Bool, forTrack track: MdsTrack) {
        let listenInfo = getOrCreateTrackListenInfoMO(forTrack: track.trackId)
        if fullyListened != listenInfo.fullyListened {
            listenInfo.lastListened = Date()
            listenInfo.fullyListened = fullyListened
            save()
            notify(ofChanging: [.lastListened, .fullyListened], of: track)
        }
        else {
            listenInfo.lastListened = Date()
            save()
            notify(ofChanging: [.lastListened], of: track)
        }
    }
}
