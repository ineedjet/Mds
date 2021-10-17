import XCTest
@testable import Mds

class CollectionExtensionsTests: XCTestCase {
    func testOptional() {
        let arr = [1,2,3]
        XCTAssertEqual(arr[optional: -1], nil)
        XCTAssertEqual(arr[optional: 0], 1)
        XCTAssertEqual(arr[optional: 1], 2)
        XCTAssertEqual(arr[optional: 2], 3)
        XCTAssertEqual(arr[optional: 3], nil)
        XCTAssertEqual(arr[optional: .max], nil)
    }

    func testSubtract() {
        let arr = [1,2,3,4,5]
        XCTAssertEqual(arr.subtract([1,2,3,4,5]), [])
        XCTAssertEqual(arr.subtract([3,4,5]), [0,1])
        XCTAssertEqual(arr.subtract([1,2,3]), [3,4])
        XCTAssertEqual(arr.subtract([2,4]), [0,2,4])
        XCTAssertEqual(arr.subtract([]), [0,1,2,3,4])
        XCTAssertEqual(arr.subtract([6]), nil)
    }
}
