// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest
@testable import Element

class UniversalLinkTests: XCTestCase {

    enum UniversalLinkTestError: Error {
        case invalidURL
    }

    func testInitialization() throws {
        guard let url = URL(string: "https://example.com") else {
            throw UniversalLinkTestError.invalidURL
        }
        let universalLink = UniversalLink(url: url)
        XCTAssertEqual(universalLink.url, url)
        XCTAssertTrue(universalLink.pathParams.isEmpty)
        XCTAssertTrue(universalLink.queryParams.isEmpty)
    }

    func testRegistrationLink() throws {
        guard let url = URL(string: "https://app.element.io/#/register/?hs_url=matrix.example.com&is_url=identity.example.com") else {
            throw UniversalLinkTestError.invalidURL
        }
        let universalLink = UniversalLink(url: url)
        XCTAssertEqual(universalLink.url, url)
        XCTAssertEqual(universalLink.pathParams.count, 1)
        XCTAssertEqual(universalLink.pathParams.first, "register")
        XCTAssertEqual(universalLink.queryParams.count, 2)
        XCTAssertEqual(universalLink.homeserverUrl, "matrix.example.com")
        XCTAssertEqual(universalLink.identityServerUrl, "identity.example.com")
    }

    func testLoginLink() throws {
        guard let url = URL(string: "https://mobile.element.io/?hs_url=matrix.example.com&is_url=identity.example.com") else {
            throw UniversalLinkTestError.invalidURL
        }
        let universalLink = UniversalLink(url: url)
        XCTAssertEqual(universalLink.url, url)
        XCTAssertTrue(universalLink.pathParams.isEmpty)
        XCTAssertEqual(universalLink.queryParams.count, 2)
        XCTAssertEqual(universalLink.homeserverUrl, "matrix.example.com")
        XCTAssertEqual(universalLink.identityServerUrl, "identity.example.com")
    }

    func testPathParams() throws {
        guard let url = URL(string: "https://mobile.element.io/#/param1/param2/param3?hs_url=matrix.example.com&is_url=identity.example.com") else {
            throw UniversalLinkTestError.invalidURL
        }
        let universalLink = UniversalLink(url: url)
        XCTAssertEqual(universalLink.url, url)
        XCTAssertEqual(universalLink.pathParams.count, 3)
        XCTAssertEqual(universalLink.pathParams[0], "param1")
        XCTAssertEqual(universalLink.pathParams[1], "param2")
        XCTAssertEqual(universalLink.pathParams[2], "param3")
        XCTAssertEqual(universalLink.queryParams.count, 2)
        XCTAssertEqual(universalLink.homeserverUrl, "matrix.example.com")
        XCTAssertEqual(universalLink.identityServerUrl, "identity.example.com")
    }

    func testVia() throws {
        guard let url = URL(string: "https://mobile.element.io/?hs_url=matrix.example.com&is_url=identity.example.com&via=param1&via=param2") else {
            throw UniversalLinkTestError.invalidURL
        }
        let universalLink = UniversalLink(url: url)
        XCTAssertEqual(universalLink.url, url)
        XCTAssertEqual(universalLink.queryParams.count, 3)
        XCTAssertEqual(universalLink.homeserverUrl, "matrix.example.com")
        XCTAssertEqual(universalLink.identityServerUrl, "identity.example.com")
        XCTAssertEqual(universalLink.via, ["param1", "param2"])
    }

    func testDescription() throws {
        let str = "https://mobile.element.io/?hs_url=matrix.example.com&is_url=identity.example.com&via=param1&via=param2"
        guard let url = URL(string: str) else {
            throw UniversalLinkTestError.invalidURL
        }
        let universalLink = UniversalLink(url: url)
        let desc = String(format: "<UniversalLink: %@>", str)
        XCTAssertEqual(universalLink.description, desc)
    }

}
