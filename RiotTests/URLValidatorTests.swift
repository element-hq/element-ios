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

class URLValidatorTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testWithOnlyURLEvent() {
        guard let event = MXEvent(fromJSON: [
            "content": [
                kMXMessageBodyKey: "https://www.example.com"
            ]
        ]) else {
            XCTFail("Failed to setup test conditions")
            return
        }

        guard let url = URL(string: "https://www.example.com") else {
            XCTFail("Failed to setup test conditions")
            return
        }

        let result = URLValidator.validateTappedURL(url, in: event)

        XCTAssertFalse(result.shouldShowConfirmationAlert, "Should not show a confirmation alert for given event and url")
        XCTAssertNil(result.visibleURLString)
    }

    func testWithHTMLEvent() {
        guard let event = MXEvent(fromJSON: [
            "content": [
                kMXMessageBodyKey: "[link](https://www.example.com)",
                "format": kMXRoomMessageFormatHTML,
                "formatted_body": "<a href=\"https://www.example.com\">link</a>"
            ]
        ]) else {
            XCTFail("Failed to setup test conditions")
            return
        }

        guard let url = URL(string: "https://www.example.com") else {
            XCTFail("Failed to setup test conditions")
            return
        }

        let result = URLValidator.validateTappedURL(url, in: event)

        XCTAssertTrue(result.shouldShowConfirmationAlert, "Should show a confirmation alert for given event and url")
        XCTAssertEqual(result.visibleURLString, "link")
    }

    func testWithRTLOverriddenEvent() {
        let realLink = "https://www.dangerous.com/=qhcraes#/moc.elgoog.www//:sptth"
        let visibleLink = realLink.vc_reversed()

        guard let event = MXEvent(fromJSON: [
            "content": [
                kMXMessageBodyKey: "\u{202E}" + visibleLink
            ]
        ]) else {
            XCTFail("Failed to setup test conditions")
            return
        }

        guard let url = URL(string: realLink) else {
            XCTFail("Failed to setup test conditions")
            return
        }

        let result = URLValidator.validateTappedURL(url, in: event)

        XCTAssertTrue(result.shouldShowConfirmationAlert, "Should show a confirmation alert for given event and url")
        XCTAssertEqual(result.visibleURLString, visibleLink)
    }
}
