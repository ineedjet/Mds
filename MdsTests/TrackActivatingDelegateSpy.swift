import XCTest
@testable import Mds

class TrackActivatingDelegateSpy: TrackActivatingControllerDelegate {
    private(set) var actionSelectionRequests: [(MdsTrack, [TrackAction], Any?, (TrackAction) -> Void)] = []
    func controller(_ controller: AnyController, selectActionFor track: MdsTrack, from availableActions: [TrackAction], near view: Any?, answerCallback: @escaping (TrackAction) -> Void) {
        actionSelectionRequests.append((track, availableActions, view, answerCallback))
    }

    private(set) var downloadConfirmationRequests: [(MdsTrack, Int64, () -> Void, () -> Void)] = []
    func controller(_ controller: AnyController, confirmDownloadOf track: MdsTrack, withNewSize newSize: Int64, callbackIfYes: @escaping () -> Void, callbackIfNo: @escaping () -> Void) {
        downloadConfirmationRequests.append((track, newSize, callbackIfYes, callbackIfNo))
    }

    func reply(confirm: Bool) {
        guard let request = downloadConfirmationRequests.first else {
            fatalError("No pending requests")
        }
        downloadConfirmationRequests = Array(downloadConfirmationRequests.suffix(from: 1))
        if confirm {
            request.2()
        }
        else {
            request.3()
        }
    }

    private(set) var playerStateUpdateRequests: Int = 0
    func controllerDidUpdatePlayerState(_ controller: AnyController) {
        playerStateUpdateRequests += 1
    }

    func controllerDidReceiveNewPlayerPosition(_ controller: AnyController) {
        fatalError("Not implemented")
    }

    func controllerDidReceiveNewPlayerDuration(_ controller: AnyController) {
        fatalError("Not implemented")
    }

    func controllerDidReceiveNewSleepTimerValue(_ controller: AnyController) {
        fatalError("Not implemented")
    }

    func controllerDidUpdateMigrationStatus(_ controller: AnyController) {
        fatalError("Not implemented")
    }

    private(set) var reportedErrors: [Error] = []
    func controller(_ controller: AnyController, didReportError error: Error) {
        reportedErrors.append(error)
    }
}

func XCTAssertDownloadConfirmationRequests(_ left: TrackActivatingDelegateSpy, _ right: [(MdsTrack, Int64)], file: StaticString = #file, line: UInt = #line) {
    let leftRequests = left.downloadConfirmationRequests
    XCTAssertEqual(leftRequests.count, right.count, "[ConfirmationRequest] length", file: file, line: line)
    guard leftRequests.count == right.count else {
        return
    }
    for i in 0..<leftRequests.count {
        let (leftTrack, leftFileSize, _, _) = leftRequests[i]
        let (rightTrack, rightFileSize) = right[i]
        XCTAssertEqual(leftTrack.trackId, rightTrack.trackId, "TrackId of ConfirmationRequest [\(i)]", file: file, line: line)
        XCTAssertEqual(leftFileSize, rightFileSize, "FileSize of ConfirmationRequest [\(i)]", file: file, line: line)
    }
}
