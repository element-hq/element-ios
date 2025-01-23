// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest
@testable import Element

class String_Element: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRTLOverride() {
        let string1 = "\u{202E}example.com/#/5=tcds=qhcraes#/moc.elgoog.www//:sptth"
        XCTAssertTrue(string1.vc_containsRTLOverride(), "String contains RTL override")

        let string2 = "http://example.com/#/5=tcds=qhcraes#/moc.elgoog.www//:sptth"
        XCTAssertFalse(string2.vc_containsRTLOverride(), "String does not contain RTL override")
    }

    func testReversed() {
        let string1 = ""
        XCTAssertEqual(string1.vc_reversed(), "")

        let string2 = "a"
        XCTAssertEqual(string2.vc_reversed(), "a")

        let string3 = "ab"
        XCTAssertEqual(string3.vc_reversed(), "ba")
    }
    
    func testNilIfEmpty() {
        XCTAssertNil("".vc_nilIfEmpty())
        XCTAssertNotNil(" ".vc_nilIfEmpty())
        XCTAssertNotNil("Johnny was here".vc_nilIfEmpty())
    }
}
