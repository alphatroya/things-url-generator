//
// Things URL generator
// 2021 Alexey Korolev <alphatroya@gmail.com>
//

import Foundation
import XCTest

final class thingsTests: XCTestCase {
    // MARK: Internal

    static var allTests = [
        ("testFailureEmpty", testFailureEmpty),
        ("testFailureWithoutTitle", testFailureWithoutTitle),
        ("testSuccessOneTodo", testSuccessOneTodo),
        ("testSuccessOnlyTitle", testSuccessOnlyTitle),
        ("testSuccessTwoTodo", testSuccessTwoTodo),
    ]

    func testSuccessOneTodo() throws {
        try XCTAssertEqual(output(for: "# Foo\n- [ ] First"), "things:///add-project?title=Foo&to-dos=%20First&reveal=true")
    }

    func testSuccessTwoTodo() throws {
        try XCTAssertEqual(
            output(for: "# Foo\n- [ ] First\n- [ ] Second"),
            "things:///add-project?title=Foo&to-dos=%20First%0A%20Second&reveal=true"
        )
    }

    func testSuccessOnlyTitle() throws {
        try XCTAssertEqual(output(for: "# Foo\n"), "things:///add-project?title=Foo&reveal=true")
    }

    func testFailureWithoutTitle() throws {
        XCTAssertThrowsError(try output(for: "Foo\n"))
    }

    func testFailureEmpty() throws {
        XCTAssertThrowsError(try output(for: ""))
    }

    func testSuccessTitleWithDescription() throws {
        try XCTAssertEqual(output(for: "# Foo\nNotes"),  "things:///add-project?title=Foo&notes=Notes&reveal=true")
    }

    func testSuccessTitleWithDescriptionMultiline() throws {
        try XCTAssertEqual(output(for: "# Foo\nNotes\nSecondLine"),  "things:///add-project?title=Foo&notes=Notes%0ASecondLine&reveal=true")
    }

    func testSuccessTitleWithDescriptionMultilineWithNotes() throws {
        try XCTAssertEqual(output(for: "# Foo\nNotes\nSecondLine\n- [ ] 1\n- [ ] 2"),  "things:///add-project?title=Foo&notes=Notes%0ASecondLine&to-dos=%201%0A%202&reveal=true")
    }

    // MARK: Private

    /// Returns path to the built products directory.
    private var productsDirectory: URL {
        #if os(macOS)
            for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
                return bundle.bundleURL.deletingLastPathComponent()
            }
            fatalError("couldn't find the products directory")
        #else
            return Bundle.main.bundleURL
        #endif
    }

    private func output(for input: String) throws -> String {
        guard #available(macOS 10.15.4, *) else {
            return ""
        }

        let fooBinary = productsDirectory.appendingPathComponent("things-url-generator")

        let process = Process()
        process.executableURL = fooBinary

        let stdOut = Pipe()
        process.standardOutput = stdOut

        let stdErr = Pipe()
        process.standardError = stdErr

        let stdIn = Pipe()
        process.standardInput = stdIn

        try process.run()
        try stdIn.fileHandleForWriting.write(contentsOf: input.data(using: .utf8)!)
        try stdIn.fileHandleForWriting.close()
        process.waitUntilExit()

        let errData = stdErr.fileHandleForReading.readDataToEndOfFile()
        if !errData.isEmpty, let errStr = String(data: errData, encoding: .utf8) {
            throw errStr
        }

        let data = stdOut.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension String: Error {}
