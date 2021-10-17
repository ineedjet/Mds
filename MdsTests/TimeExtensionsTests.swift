import XCTest
@testable import Mds

class TimeExtensionsTests: XCTestCase {
    func testIntAsTime() {
        XCTAssertEqual(0.asTime, "0:00")
        XCTAssertEqual(5.asTime, "0:05")
        XCTAssertEqual(10.asTime, "0:10")
        XCTAssertEqual(59.asTime, "0:59")
        XCTAssertEqual(60.asTime, "1:00")
        XCTAssertEqual(61.asTime, "1:01")
        XCTAssertEqual(599.asTime, "9:59")
        XCTAssertEqual(600.asTime, "10:00")
        XCTAssertEqual(601.asTime, "10:01")
        XCTAssertEqual(3599.asTime, "59:59")
        XCTAssertEqual(3600.asTime, "1:00:00")
        XCTAssertEqual(3601.asTime, "1:00:01")
        XCTAssertEqual(36010.asTime, "10:00:10")
        XCTAssertEqual(360100.asTime, "100:01:40")
        XCTAssertEqual(3601000.asTime, "1000:16:40")
    }
}
