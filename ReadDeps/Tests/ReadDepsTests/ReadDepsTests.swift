import XCTest
@testable import ReadDeps

final class ReadDepsTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ReadDeps().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
