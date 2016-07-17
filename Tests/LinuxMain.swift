#if os(Linux)

import XCTest
@testable import GCloudTestSuite

XCTMain([
  testCase(GCloudTests.allTests),
])
#endif
