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
