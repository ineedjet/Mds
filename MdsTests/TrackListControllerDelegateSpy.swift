import XCTest
@testable import Mds

class TrackListControllerDelegateSpy: TrackActivatingDelegateSpy, TrackListControllerDelegate {
    private var drasticDataChangeRequests: Int = 0
    func controllerDidDrasticallyChangeData(_ controller: AnyController) {
        drasticDataChangeRequests += 1
    }

    private var removalRequests: [(sections: IndexSet, rows: [IndexPath])] = []
    func controller(_ controller: AnyController, didRemoveSections sections: IndexSet, andRowsAt indexPaths: [IndexPath]) {
        removalRequests.append((sections, indexPaths))
    }

    private var additionRequests: [(sections: IndexSet, rows: [IndexPath])] = []
    func controller(_ controller: AnyController, didAddSections sections: IndexSet, andRowsAt indexPaths: [IndexPath]) {
        additionRequests.append((sections, indexPaths))
    }

    private var rowUpdateRequests: [IndexPath] = []
    func controller(_ controller: AnyController, didUpdateRowsAt indexPaths: [IndexPath]) {
        rowUpdateRequests.append(contentsOf: indexPaths)
    }

    private var rowMoveRequests: [(at: IndexPath, to: IndexPath)] = []
    func controller(_ controller: AnyController, didMoveRowAt indexPath: IndexPath, to newIndexPath: IndexPath) {
        rowMoveRequests.append((indexPath, newIndexPath))
    }

    func verifyAndReset(drasticDataChangeRequests: Int = 0,
                        rowUpdateRequests: Set<IndexPath> = [],
                        additionRequests: [(sections: [Int], rows: [IndexPath])] = [],
                        removalRequests: [(sections: [Int], rows: [IndexPath])] = [],
                        rowMoveRequests: [(at: IndexPath, to: IndexPath)] = [],
                        file: StaticString = #file,
                        line: UInt = #line) {
        XCTAssertEqual(self.drasticDataChangeRequests, drasticDataChangeRequests, "drasticDataChangeRequests", file: file, line: line)
        self.drasticDataChangeRequests = 0

        XCTAssertEqual(self.additionRequests, additionRequests, "additionRequests", file: file, line: line)
        self.additionRequests = []

        XCTAssertEqual(self.removalRequests, removalRequests, "removalRequests", file: file, line: line)
        self.removalRequests = []

        XCTAssertSet(Set(self.rowUpdateRequests), rowUpdateRequests, "unique rowUpdateRequests", file: file, line: line)
        self.rowUpdateRequests = []

        XCTAssertEqual(self.rowMoveRequests, rowMoveRequests, "rowMoveRequests", file: file, line: line)
        self.rowMoveRequests = []
    }
}
