// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
