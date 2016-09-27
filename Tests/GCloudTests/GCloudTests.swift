import XCTest
@testable import Datastore

class GCloudTests: XCTestCase {
    func testReality() {
		XCTAssert(2 + 2 == 4, "Something is severely wrong here.")
	}
}

extension GCloudTests {
    static var allTests: [(String, (GCloudTests) -> () throws -> Void)] {
        return [
           ("testReality", testReality),
        ]
    }
}
