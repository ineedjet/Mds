import XCTest
@testable import Mds

// These, and a few other tests in this project, assume that `Array.sorted` produces a stable sort,
// which is not guaranteed, but is true for Swift 5/iOS 13. Be prepared to update these tests later.
class ComparableExtensionsTests: XCTestCase {
    private struct A: Equatable, CustomStringConvertible {
        var comparable: Int?
        var payload: Int
        var description: String { "<\(comparable?.description ?? "nil"), \(payload)>" }
    }

    func testOptionalLessThan() {
        XCTAssertEqual([3,1,2,nil].sorted{$0 < $1}, [nil,1,2,3])
        XCTAssertEqual([nil,3,nil,nil].sorted{$0 < $1}, [nil,nil,nil,3])

        XCTAssertEqual(
            [
                A(comparable: 3, payload: 3),
                A(comparable: nil, payload: 0),
                A(comparable: 3, payload: 4),
                A(comparable: nil, payload: 1),
                A(comparable: nil, payload: 2)
            ].sorted{$0.comparable < $1.comparable},
            [
                A(comparable: nil, payload: 0),
                A(comparable: nil, payload: 1),
                A(comparable: nil, payload: 2),
                A(comparable: 3, payload: 3),
                A(comparable: 3, payload: 4)
            ],
            "Sort should be stable"
        )
    }

    func testOptionalGreaterThan() {
        XCTAssertEqual([3,1,2,nil].sorted{$0 > $1}, [3,2,1,nil])
        XCTAssertEqual([nil,3,nil,nil].sorted{$0 > $1}, [3,nil,nil,nil])

        XCTAssertEqual(
            [
                A(comparable: 3, payload: 0),
                A(comparable: nil, payload: 2),
                A(comparable: nil, payload: 3),
                A(comparable: 3, payload: 1),
                A(comparable: nil, payload: 4)
            ].sorted{$0.comparable > $1.comparable},
            [
                A(comparable: 3, payload: 0),
                A(comparable: 3, payload: 1),
                A(comparable: nil, payload: 2),
                A(comparable: nil, payload: 3),
                A(comparable: nil, payload: 4)
            ],
            "Sort should be stable"
        )
    }
}
