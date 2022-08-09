// 
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
}
