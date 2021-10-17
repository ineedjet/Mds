import UIKit
import CoreData

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func applicationDidFinishLaunching(_ application: UIApplication) {
        #if DEBUG
        guard NSClassFromString("XCTest") == nil else {
            // Unit-tests are running, no further initialization required
            window = nil
            return
        }
        if ProcessInfo.processInfo.arguments.contains("-clean") {
            // clean start
            let fileManager = FileManager.default
            
            let docsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let mdURL = docsUrl.appendingPathComponent("metadata.sqlite")
            try? fileManager.removeItem(at: mdURL)

            let appDataUrl = try! fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let persistentCacheDir = appDataUrl.appendingPathComponent("Downloads")
            try? fileManager.removeItem(at: persistentCacheDir)

            UserDefaults.standard.hideFullyListened = false
            UserDefaults.standard.sortingMode = .author
        }
        #endif
        DataStorage.initialize()
        if let (track, serverId) = DataStorage.reader.getLastTrack(), !(track.fullyListened && track.lastPosition == 0) {
            RealAudioPlayer.shared.select(track, onServer: serverId)
        }

        let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        UserDefaults.standard.set(build, forKey: "build_number")
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        guard identifier == DownloadManagerBackgroundURLSessionIdentifier else {
            print("Someone woke us up for no reason")
            return
        }
        print("Application relaunched to handle background downloads")
        DownloadManager.shared.setBackgroundCompletionHandler(completionHandler)
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        DataStorage.invalidateTrackCache()
        DataStorage.invalidateListenInfoCache()
    }
}

