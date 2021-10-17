import XCTest
@testable import Mds

class SearchableTrackListControllerTests: XCTestCase {
    private var allData: [MdsTrack]!
    private var dataByAuthor: [String : [MdsTrack]]!

    override func setUp() {
        DataStorage.initializeForUnitTests()
        allData = DataStorage.reader.getAllTracks()
        dataByAuthor = Dictionary(grouping: allData) { $0.trackAuthor }
            .mapValues { $0.sorted { $0.trackTitle < $1.trackTitle } }
        super.setUp()
        continueAfterFailure = false
    }

    func testSearch() {
        let target = SearchableTrackListController()
        target.searchTerm = "тЕ"
        let filteredData1 = allData.filter {
               $0.trackAuthor.lowercased().contains("те")
            || $0.trackAuthor.lowercased().contains("тё")
            || $0.trackTitle.lowercased().contains("те")
            || $0.trackTitle.lowercased().contains("тё") }
        let data1 = Dictionary(grouping: filteredData1) { $0.trackAuthor }
            .mapValues { $0.sorted { $0.trackTitle < $1.trackTitle } }
        XCTAssert(target,
                  headerField: .author,
                  visibleCount: filteredData1.count,
                  data: data1,
                  orderedKeys: data1.keys.sorted(),
                  extractTitle: {$0!},
                  extractIndex: nil,
                  titleMatchesIndex: {$0!.starts(with: $1)})

        target.searchTerm = "Ма"
        let filteredData2 = allData.filter {
               $0.trackAuthor.lowercased().contains("ма")
            || $0.trackTitle.lowercased().contains("ма") }
        let data2 = Dictionary(grouping: filteredData2) { $0.trackAuthor }
            .mapValues { $0.sorted { $0.trackTitle < $1.trackTitle } }
        XCTAssert(target,
                  headerField: .author,
                  visibleCount: filteredData2.count,
                  data: data2,
                  orderedKeys: data2.keys.sorted(),
                  extractTitle: {$0!},
                  extractIndex: nil,
                  titleMatchesIndex: {$0!.starts(with: $1)})

        target.searchTerm = ""
        XCTAssert(target,
                  headerField: .author,
                  visibleCount: allData.count,
                  data: dataByAuthor,
                  orderedKeys: dataByAuthor.keys.sorted(),
                  extractTitle: {$0!},
                  extractIndex: nil,
                  titleMatchesIndex: {$0!.starts(with: $1)})
    }

    func testTableViewUpdates() {
        let audioPlayerSpy = AudioPlayerSpy()
        let target = SearchableTrackListController(audioPlayer: audioPlayerSpy)
        let delegateSpy = TrackListControllerDelegateSpy()
        target.delegate = delegateSpy
        XCTAssert(target,
                  headerField: .author,
                  visibleCount: allData.count,
                  data: dataByAuthor,
                  orderedKeys: dataByAuthor.keys.sorted(),
                  extractTitle: {$0!},
                  extractIndex: nil,
                  titleMatchesIndex: {$0!.starts(with: $1)})

        let singleTrack = dataByAuthor.first{$0.value.count == 1}!
        let track = singleTrack.value[0]
        let trackIndexPath = target.indexPath(of: track)!
        delegateSpy.verifyAndReset()
        audioPlayerSpy.state = .preparing(track)
        delegateSpy.verifyAndReset(rowUpdateRequests: [trackIndexPath])
        audioPlayerSpy.state = .loading(track)
        delegateSpy.verifyAndReset(rowUpdateRequests: [trackIndexPath])
        audioPlayerSpy.state = .playing(track)
        delegateSpy.verifyAndReset(rowUpdateRequests: [trackIndexPath])
        DataStorage.writer.set(fullyListened: true, forTrack: track)
        delegateSpy.verifyAndReset(rowUpdateRequests: [trackIndexPath])
        audioPlayerSpy.state = .idle
        delegateSpy.verifyAndReset(rowUpdateRequests: [trackIndexPath])

        DataStorage.writer.set(fullyListened: true, forTrack: track)
        delegateSpy.verifyAndReset(rowUpdateRequests: [])
        DataStorage.writer.set(fullyListened: false, forTrack: track)
        delegateSpy.verifyAndReset(rowUpdateRequests: [trackIndexPath])
        DataStorage.writer.set(fullyListened: true, forTrack: track)
        delegateSpy.verifyAndReset(rowUpdateRequests: [trackIndexPath])
    }
}
