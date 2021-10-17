import CoreData

typealias TrackId = Int32
typealias RecordId = Int32

class DataStorage {
    private static var _instance: DataStorage?
    static var instance: DataStorage {
        if let instance = _instance {
            return instance
        }
        fatalError("Use DataStorage.initialize to initialize data storage")
    }

    /// Initialize with metadata in default location
    static func initialize() {
        assert(_instance == nil, "Re-initialization of the DataStorage is not supported")
        _instance = PersistentMetadataStorage()
    }

    /// Initialize without metadata
    static func initialize(storeURL: URL) {
        assert(_instance == nil, "Re-initialization of the DataStorage is not supported")
        _instance = NoMetadataStorage(storeURL: storeURL)
    }

    #if DEBUG
    /// Initialize with metadata in memory
    static func initializeForUnitTests() {
        _instance = InMemoryMetadataStorage()
        DataStorage.invalidateTrackCache()
        DataStorage.invalidateListenInfoCache()
    }
    #endif

    let readonlyContainer: NSPersistentContainer
    let metadataContainer: NSPersistentContainer?

    private static func loadContainer(name: String, description: NSPersistentStoreDescription?) -> NSPersistentContainer? {
        guard let description = description else {
            return nil
        }
        description.shouldAddStoreAsynchronously = false
        let container = NSPersistentContainer(name: name)
        container.persistentStoreDescriptions = [description]
        var error = false
        container.loadPersistentStores(completionHandler: {
            if let e = $1 as NSError? {
                error = true
                print("Failed to initialize storage \"\(name)\": \(e), \(e.userInfo)")
            }
        })
        return error ? nil : container
    }

    private init(readonlyStore: NSPersistentStoreDescription, metadataStore: NSPersistentStoreDescription?) {
        guard let c = DataStorage.loadContainer(name: "Mds", description: readonlyStore) else {
            fatalError()
        }
        self.readonlyContainer = c
        self.metadataContainer = DataStorage.loadContainer(name: "MdsMetadata", description: metadataStore)
    }

    private final class NoMetadataStorage: DataStorage {
        init(storeURL: URL) {
            let roDescription = NSPersistentStoreDescription(url: storeURL)
            // disable Write-Ahead Logging to consolidate the whole DB in a single file
            roDescription.setValue("DELETE" as NSString, forPragmaNamed: "journal_mode")
            super.init(readonlyStore: roDescription, metadataStore: nil)
        }
    }

    private class MetadataStorage: DataStorage {
        init(metadataStore: NSPersistentStoreDescription) {
            guard let storeURL = Bundle.main.url(forResource: "storage", withExtension: "sqlite") else {
                fatalError("Cannot find `storage.sqlite` in the main bundle")
            }
            let roDescription = NSPersistentStoreDescription(url: storeURL)
            roDescription.setOption(true as NSNumber, forKey: NSReadOnlyPersistentStoreOption)
            super.init(readonlyStore: roDescription, metadataStore: metadataStore)
        }
    }

    private final class PersistentMetadataStorage: MetadataStorage {
        init() {
            guard let docsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                fatalError("Cannot obtain the documents folder")
            }
            let mdURL = docsUrl.appendingPathComponent("metadata.sqlite")
            let mdDescription = NSPersistentStoreDescription(url: mdURL)
            // disable Write-Ahead Logging to consolidate the whole DB in a single file
            mdDescription.setValue("DELETE" as NSString, forPragmaNamed: "journal_mode")
            super.init(metadataStore: mdDescription)
        }
    }

    private final class InMemoryMetadataStorage: MetadataStorage {
        init() {
            let mdDescription = NSPersistentStoreDescription()
            mdDescription.type = NSInMemoryStoreType
            super.init(metadataStore: mdDescription)
        }
    }
}
