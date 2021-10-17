import XCTest
@testable import Mds

class DownloadManagerSpy: DownloadManager {
    init() {
        super.init(recordCache: RecordCacheMock(strict: false), dataReader: DataReaderDummy())
    }

    private(set) var estimateSizeRequests: [(MdsTrack, ServerId, (Int64?) -> Void)] = []
    override func estimateSize(ofTrack track: MdsTrack, fromServer server: ServerId, callback: @escaping (Int64?) -> Void) {
        estimateSizeRequests.append((track, server, callback))
    }

    func provideSizeEstimate(_ size: Int64?) {
        guard let request = estimateSizeRequests.first else {
            fatalError("No pending requests")
        }
        estimateSizeRequests = Array(estimateSizeRequests.suffix(from: 1))
        request.2(size)
    }

    private(set) var downloadRequests: [(MdsTrack, ServerId, Bool)] = []
    override func download(_ track: MdsTrack, from serverId: ServerId, onlyIfPrepared: Bool) {
        cancelPreparation(ofTrack: track)
        downloadRequests.append((track, serverId, onlyIfPrepared))
    }

    private(set) var cancelRequests: [MdsTrack] = []
    override func cancelDownload(_ track: MdsTrack) {
        cancelPreparation(ofTrack: track)
        cancelRequests.append(track)
    }
}

func XCTAssertEstimateSizeRequests(_ left: DownloadManagerSpy, _ right: [(MdsTrack, ServerId)], file: StaticString = #file, line: UInt = #line) {
    let leftRequests = left.estimateSizeRequests
    XCTAssertEqual(leftRequests.count, right.count, "[EstimateSize] length", file: file, line: line)
    guard leftRequests.count == right.count else {
        return
    }
    for i in 0..<leftRequests.count {
        let (leftTrack, leftServer, _) = leftRequests[i]
        let (rightTrack, rightServer) = right[i]
        XCTAssertEqual(leftTrack.trackId, rightTrack.trackId, "TrackId of EstimateSize [\(i)]", file: file, line: line)
        XCTAssertEqual(leftServer, rightServer, "ServerId of EstimateSize [\(i)]", file: file, line: line)
    }
}

func XCTAssertDownloadRequests(_ left: DownloadManagerSpy, _ right: [(MdsTrack, ServerId, Bool)], file: StaticString = #file, line: UInt = #line) {
    let leftRequests = left.downloadRequests
    XCTAssertEqual(leftRequests.count, right.count,"[DownloadRequest] length", file: file, line: line)
    guard leftRequests.count == right.count else {
        return
    }
    for i in 0..<leftRequests.count {
        let (leftTrack, leftServer, leftPrepared) = leftRequests[i]
        let (rightTrack, rightServer, rightPrepared) = right[i]
        XCTAssertEqual(leftTrack.trackId, rightTrack.trackId, "TrackId of DownloadRequest [\(i)]", file: file, line: line)
        XCTAssertEqual(leftServer, rightServer, "ServerId of DownloadRequest [\(i)]", file: file, line: line)
        XCTAssertEqual(leftPrepared, rightPrepared, "OnlyIfPrepared of DownloadRequest [\(i)]", file: file, line: line)
    }
}
