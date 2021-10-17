import XCTest
@testable import Mds

fileprivate extension Date {
    var yearString: String {
        return "\(Calendar.current.component(.year, from: self))"
    }
}

fileprivate func dateLessThan(_ a: MdsTrack, _ b: MdsTrack) -> Bool {
    guard let adate = a.date else {
        return b.date != nil
    }
    return b.date != nil && adate < b.date!
}

class MdsTrackListControllerTests: XCTestCase {
    private var allData: [MdsTrack]!
    private var dataByAuthor: [String : [MdsTrack]]!
    private var dataByDate: [String? : [MdsTrack]]!
    private var dataByStation: [String? : [MdsTrack]]!
    private var dataByDurationAsc: [String : [MdsTrack]]!
    private var dataByDurationDesc: [String : [MdsTrack]]!

    override func setUp() {
        DataStorage.initializeForUnitTests()
        allData = DataStorage.reader.getAllTracks()
        dataByAuthor = Dictionary(grouping: allData) { $0.trackAuthor }
            .mapValues { $0.sorted { $0.trackTitle < $1.trackTitle } }
        dataByDate = Dictionary(grouping: allData) { $0.date?.yearString }
            .mapValues { $0.sorted(by: dateLessThan) }
        dataByStation = Dictionary(grouping: allData) { $0.station }
            .mapValues { $0.sorted(by: dateLessThan) }
        dataByDurationAsc = Dictionary(grouping: allData) { $0.durationGroup }
            .mapValues { $0.sorted { $0.durationInMinutes < $1.durationInMinutes } }
        dataByDurationDesc = Dictionary(grouping: allData) { $0.durationGroup }
            .mapValues { $0.sorted { $0.durationInMinutes > $1.durationInMinutes } }
        super.setUp()
        continueAfterFailure = false
    }

    func testSortByAuthor() {
        let target = MdsTrackListController(sortedBy: .author, hideFullyListened: false)
        XCTAssert(target,
                  headerField: .author,
                  visibleCount: allData.count,
                  data: dataByAuthor,
                  orderedKeys: dataByAuthor.keys.sorted(),
                  extractTitle: {$0!},
                  extractIndex: {$0!.prefix(1).uppercased()},
                  titleMatchesIndex: {$0!.starts(with: $1)})
    }

    func testSortByDate() {
        let target = MdsTrackListController(sortedBy: .date, hideFullyListened: false)
        XCTAssert(target,
                  headerField: .year,
                  visibleCount: allData.count,
                  data: dataByDate,
                  orderedKeys: dataByDate.keys.sorted{$0 == nil || $1 != nil && $0! < $1!},
                  extractTitle: {$0 ?? ""},
                  extractIndex: {$0?.suffix(2).uppercased() ?? ".."},
                  titleMatchesIndex: {$0?.hasSuffix($1) ?? ($1 == "..")})
    }

    func testSortByStation() {
        let target = MdsTrackListController(sortedBy: .station, hideFullyListened: false)
        XCTAssert(target,
                  headerField: .station,
                  visibleCount: allData.count,
                  data: dataByStation,
                  orderedKeys: dataByStation.keys.sorted{$0 == nil || $1 != nil && $0! < $1!},
                  extractTitle: {$0 ?? ""},
                  extractIndex: {$0?.prefix(2).uppercased() ?? ".."},
                  titleMatchesIndex: {$0?.uppercased().starts(with: $1) ?? ($1 == "..")})
    }

    func testSortByDurationAsc() {
        let target = MdsTrackListController(sortedBy: .durationAsc, hideFullyListened: false)
        XCTAssert(target,
                  headerField: .duration,
                  visibleCount: allData.count,
                  data: dataByDurationAsc,
                  orderedKeys: dataByDurationAsc.keys.sorted{$0.starts(with: "Короче") || !$1.starts(with: "Короче") && $0 < $1},
                  extractTitle: {$0!},
                  extractIndex: {Int($0!.prefix(2)) != nil ? $0!.prefix(2).uppercased() : ".."},
                  titleMatchesIndex: {$1 == ".." ? $0!.starts(with: "Короче") : $1.prefix(2).uppercased() == $0!.prefix(2).uppercased()})
    }

    func testSortByDurationDesc() {
        let target = MdsTrackListController(sortedBy: .durationDesc, hideFullyListened: false)
        XCTAssert(target,
                  headerField: .duration,
                  visibleCount: allData.count,
                  data: dataByDurationDesc,
                  orderedKeys: dataByDurationDesc.keys.sorted{$0.starts(with: "Короче") || !$1.starts(with: "Короче") && $0 < $1}.reversed(),
                  extractTitle: {$0!},
                  extractIndex: {Int($0!.prefix(2)) != nil ? $0!.prefix(2).uppercased() : ".."},
                  titleMatchesIndex: {$1 == ".." ? $0!.starts(with: "Длинее") : $1.prefix(2).uppercased() == $0!.prefix(2).uppercased()})
    }

    func testSwitchSort() {
        let target = MdsTrackListController(sortedBy: .author, hideFullyListened: false)
        let delegateSpy = TrackListControllerDelegateSpy()
        target.delegate = delegateSpy
        XCTAssert(target,
                  headerField: .author,
                  visibleCount: allData.count,
                  data: dataByAuthor,
                  orderedKeys: dataByAuthor.keys.sorted(),
                  extractTitle: {$0!},
                  extractIndex: {$0!.prefix(1).uppercased()},
                  titleMatchesIndex: {$0!.starts(with: $1)})

        target.sortingMode = .date
        delegateSpy.verifyAndReset(drasticDataChangeRequests: 1)
        XCTAssert(target,
                  headerField: .year,
                  visibleCount: allData.count,
                  data: dataByDate,
                  orderedKeys: dataByDate.keys.sorted{$0 == nil || $1 != nil && $0! < $1!},
                  extractTitle: {$0 ?? ""},
                  extractIndex: {$0?.suffix(2).uppercased() ?? ".."},
                  titleMatchesIndex: {$0?.hasSuffix($1) ?? ($1 == "..")})

        target.sortingMode = .durationAsc
        delegateSpy.verifyAndReset(drasticDataChangeRequests: 1)
        XCTAssert(target,
                  headerField: .duration,
                  visibleCount: allData.count,
                  data: dataByDurationAsc,
                  orderedKeys: dataByDurationAsc.keys.sorted{$0.starts(with: "Короче") || !$1.starts(with: "Короче") && $0 < $1},
                  extractTitle: {$0!},
                  extractIndex: {Int($0!.prefix(2)) != nil ? $0!.prefix(2).uppercased() : ".."},
                  titleMatchesIndex: {$1 == ".." ? $0!.starts(with: "Короче") : $1.prefix(2).uppercased() == $0!.prefix(2).uppercased()})

        target.sortingMode = .author
        delegateSpy.verifyAndReset(drasticDataChangeRequests: 1)
        XCTAssert(target,
                  headerField: .author,
                  visibleCount: allData.count,
                  data: dataByAuthor,
                  orderedKeys: dataByAuthor.keys.sorted(),
                  extractTitle: {$0!},
                  extractIndex: {$0!.prefix(1).uppercased()},
                  titleMatchesIndex: {$0!.starts(with: $1)})
    }

    func testNotifications() {
        let audioPlayerSpy = AudioPlayerSpy()
        let target = MdsTrackListController(sortedBy: .author, hideFullyListened: false, audioPlayer: audioPlayerSpy)
        let delegateSpy = TrackListControllerDelegateSpy()
        target.delegate = delegateSpy
        let track1 = allData[0]
        let track2 = allData[1]
        let trackIndexPath1 = target.indexPath(of: track1)!
        let trackIndexPath2 = target.indexPath(of: track2)!

        delegateSpy.verifyAndReset()
        audioPlayerSpy.state = .preparing(track1)
        delegateSpy.verifyAndReset(rowUpdateRequests: [trackIndexPath1])
        audioPlayerSpy.state = .preparing(track2)
        delegateSpy.verifyAndReset(rowUpdateRequests: [trackIndexPath1, trackIndexPath2])
        audioPlayerSpy.state = .playing(track2)
        delegateSpy.verifyAndReset(rowUpdateRequests: [trackIndexPath2])
        audioPlayerSpy.state = .paused(track2)
        delegateSpy.verifyAndReset(rowUpdateRequests: [trackIndexPath2])
        audioPlayerSpy.state = .playing(track2)
        delegateSpy.verifyAndReset(rowUpdateRequests: [trackIndexPath2])
        audioPlayerSpy.state = .preparing(track1)
        delegateSpy.verifyAndReset(rowUpdateRequests: [trackIndexPath2, trackIndexPath1])
        audioPlayerSpy.state = .idle
        delegateSpy.verifyAndReset(rowUpdateRequests: [trackIndexPath1])
    }

    func testTableViewUpdates() {
        let audioPlayerSpy = AudioPlayerSpy()
        let target = MdsTrackListController(sortedBy: .author, hideFullyListened: false, audioPlayer: audioPlayerSpy)
        let delegateSpy = TrackListControllerDelegateSpy()
        target.delegate = delegateSpy
        XCTAssert(target,
                  headerField: .author,
                  visibleCount: allData.count,
                  data: dataByAuthor,
                  orderedKeys: dataByAuthor.keys.sorted(),
                  extractTitle: {$0!},
                  extractIndex: {$0!.prefix(1).uppercased()},
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

    func testTableViewUpdatesHidingFullyListened() {
        let audioPlayerSpy = AudioPlayerSpy()
        let target = MdsTrackListController(sortedBy: .author, hideFullyListened: true, audioPlayer: audioPlayerSpy)
        let delegateSpy = TrackListControllerDelegateSpy()
        target.delegate = delegateSpy
        let unlistenedData1 = allData!
        let unlistenedDataByAuthor1 = dataByAuthor!
        XCTAssert(target,
                  headerField: .author,
                  visibleCount: unlistenedData1.count,
                  data: unlistenedDataByAuthor1,
                  orderedKeys: unlistenedDataByAuthor1.keys.sorted(),
                  extractTitle: {$0!},
                  extractIndex: {$0!.prefix(1).uppercased()},
                  titleMatchesIndex: {$0!.starts(with: $1)})

        let singleTrack = unlistenedDataByAuthor1.first{$0.value.count == 1}!
        let author = singleTrack.key
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
        delegateSpy.verifyAndReset(rowUpdateRequests: [trackIndexPath],
                                   removalRequests: [([trackIndexPath.section], [])])
        audioPlayerSpy.state = .idle
        delegateSpy.verifyAndReset()

        let unlistenedData2 = allData.filter{!$0.fullyListened}
        let unlistenedDataByAuthor2 = Dictionary(grouping: unlistenedData2) { $0.trackAuthor }
            .mapValues { $0.sorted { $0.trackTitle < $1.trackTitle } }
        XCTAssertEqual(unlistenedData2.count, unlistenedData1.count-1)
        XCTAssertEqual(unlistenedDataByAuthor2.count, unlistenedDataByAuthor1.count-1)
        XCTAssertEqual(unlistenedDataByAuthor1[author]?.count, 1)
        XCTAssertEqual(unlistenedDataByAuthor2[author]?.count, nil)
        XCTAssert(target,
                  headerField: .author,
                  visibleCount: unlistenedData2.count,
                  data: unlistenedDataByAuthor2,
                  orderedKeys: unlistenedDataByAuthor2.keys.sorted(),
                  extractTitle: {$0!},
                  extractIndex: {$0!.prefix(1).uppercased()},
                  titleMatchesIndex: {$0!.starts(with: $1)})

        DataStorage.writer.set(fullyListened: true, forTrack: track)
        delegateSpy.verifyAndReset()
        DataStorage.writer.set(lastListened: Date(), forTrack: track)
        delegateSpy.verifyAndReset()
        DataStorage.writer.set(fullyListened: false, forTrack: track)
        delegateSpy.verifyAndReset(additionRequests: [([trackIndexPath.section], [])])
        XCTAssert(target,
                  headerField: .author,
                  visibleCount: unlistenedData1.count,
                  data: unlistenedDataByAuthor1,
                  orderedKeys: unlistenedDataByAuthor1.keys.sorted(),
                  extractTitle: {$0!},
                  extractIndex: {$0!.prefix(1).uppercased()},
                  titleMatchesIndex: {$0!.starts(with: $1)})

        DataStorage.writer.set(fullyListened: true, forTrack: track)
        delegateSpy.verifyAndReset(rowUpdateRequests: [trackIndexPath],
                                   removalRequests: [([trackIndexPath.section], [])])
        XCTAssert(target,
                  headerField: .author,
                  visibleCount: unlistenedData2.count,
                  data: unlistenedDataByAuthor2,
                  orderedKeys: unlistenedDataByAuthor2.keys.sorted(),
                  extractTitle: {$0!},
                  extractIndex: {$0!.prefix(1).uppercased()},
                  titleMatchesIndex: {$0!.starts(with: $1)})
    }

    func testTableViewUpdatesHidingInSection() {
        let audioPlayerSpy = AudioPlayerSpy()
        let target = MdsTrackListController(sortedBy: .author, hideFullyListened: true, audioPlayer: audioPlayerSpy)
        let delegateSpy = TrackListControllerDelegateSpy()
        target.delegate = delegateSpy
        let unlistenedData1 = allData!
        let unlistenedDataByAuthor1 = dataByAuthor!
        XCTAssert(target,
                  headerField: .author,
                  visibleCount: unlistenedData1.count,
                  data: unlistenedDataByAuthor1,
                  orderedKeys: unlistenedDataByAuthor1.keys.sorted(),
                  extractTitle: {$0!},
                  extractIndex: {$0!.prefix(1).uppercased()},
                  titleMatchesIndex: {$0!.starts(with: $1)})

        let trackInSection = unlistenedDataByAuthor1.first{$0.value.count > 3}!
        let author = trackInSection.key
        let track = trackInSection.value[2]
        let trackIndexPath = target.indexPath(of: track)!
        delegateSpy.verifyAndReset()
        audioPlayerSpy.state = .playing(track)
        delegateSpy.verifyAndReset(rowUpdateRequests: [trackIndexPath])
        DataStorage.writer.set(fullyListened: true, forTrack: track)
        delegateSpy.verifyAndReset(rowUpdateRequests: [trackIndexPath],
                                   removalRequests: [([], [trackIndexPath])])
        audioPlayerSpy.state = .idle
        delegateSpy.verifyAndReset()

        let unlistenedData2 = allData.filter{!$0.fullyListened}
        let unlistenedDataByAuthor2 = Dictionary(grouping: unlistenedData2) { $0.trackAuthor }
            .mapValues { $0.sorted { $0.trackTitle < $1.trackTitle } }
        XCTAssertEqual(unlistenedData2.count, unlistenedData1.count-1)
        XCTAssertEqual(unlistenedDataByAuthor2.count, unlistenedDataByAuthor1.count)
        XCTAssertGreaterThan(unlistenedDataByAuthor1[author]!.count, 3)
        XCTAssertEqual(unlistenedDataByAuthor2[author]!.count, unlistenedDataByAuthor1[author]!.count-1)
        XCTAssert(target,
                  headerField: .author,
                  visibleCount: unlistenedData2.count,
                  data: unlistenedDataByAuthor2,
                  orderedKeys: unlistenedDataByAuthor2.keys.sorted(),
                  extractTitle: {$0!},
                  extractIndex: {$0!.prefix(1).uppercased()},
                  titleMatchesIndex: {$0!.starts(with: $1)})

        DataStorage.writer.set(fullyListened: true, forTrack: track)
        delegateSpy.verifyAndReset()
        DataStorage.writer.set(fullyListened: false, forTrack: track)
        delegateSpy.verifyAndReset(additionRequests: [([], [trackIndexPath])])
        XCTAssert(target,
                  headerField: .author,
                  visibleCount: unlistenedData1.count,
                  data: unlistenedDataByAuthor1,
                  orderedKeys: unlistenedDataByAuthor1.keys.sorted(),
                  extractTitle: {$0!},
                  extractIndex: {$0!.prefix(1).uppercased()},
                  titleMatchesIndex: {$0!.starts(with: $1)})

        DataStorage.writer.set(fullyListened: true, forTrack: track)
        delegateSpy.verifyAndReset(rowUpdateRequests: [trackIndexPath],
                                   removalRequests: [([], [trackIndexPath])])
        XCTAssert(target,
                  headerField: .author,
                  visibleCount: unlistenedData2.count,
                  data: unlistenedDataByAuthor2,
                  orderedKeys: unlistenedDataByAuthor2.keys.sorted(),
                  extractTitle: {$0!},
                  extractIndex: {$0!.prefix(1).uppercased()},
                  titleMatchesIndex: {$0!.starts(with: $1)})
    }
}
