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

class UserAgentParserTests: XCTestCase {

    func testAndroidUserAgents() throws {
        let uaStrings = [
            // New User Agent Implementation
            "Element dbg/1.5.0-dev (Xiaomi Mi 9T; Android 11; RKQ1.200826.002 test-keys; Flavour GooglePlay; MatrixAndroidSdk2 1.5.2)",
            "Element/1.5.0 (Samsung SM-G960F; Android 6.0.1; RKQ1.200826.002; Flavour FDroid; MatrixAndroidSdk2 1.5.2)",
            "Element/1.5.0 (Google Nexus 5; Android 7.0; RKQ1.200826.002 test test; Flavour FDroid; MatrixAndroidSdk2 1.5.2)",
            // Legacy User Agent Implementation
            "Element/1.0.0 (Linux; U; Android 6.0.1; SM-A510F Build/MMB29; Flavour GPlay; MatrixAndroidSdk2 1.0)",
            "Element/1.0.0 (Linux; Android 7.0; SM-G610M Build/NRD90M; Flavour GPlay; MatrixAndroidSdk2 1.0)"
        ]
        let userAgents = uaStrings.map { UserAgentParser.parse($0) }

        let expected = [
            UserAgent(deviceType: .mobile,
                      deviceModel: "Xiaomi Mi 9T",
                      deviceOS: "Android 11",
                      clientName: "Element dbg",
                      clientVersion: "1.5.0-dev"),
            UserAgent(deviceType: .mobile,
                      deviceModel: "Samsung SM-G960F",
                      deviceOS: "Android 6.0.1",
                      clientName: "Element",
                      clientVersion: "1.5.0"),
            UserAgent(deviceType: .mobile,
                      deviceModel: "Google Nexus 5",
                      deviceOS: "Android 7.0",
                      clientName: "Element",
                      clientVersion: "1.5.0"),
            UserAgent(deviceType: .mobile,
                      deviceModel: "SM-A510F Build/MMB29",
                      deviceOS: "Android 6.0.1",
                      clientName: "Element",
                      clientVersion: "1.0.0"),
            UserAgent(deviceType: .mobile,
                      deviceModel: "SM-G610M Build/NRD90M",
                      deviceOS: "Android 7.0",
                      clientName: "Element",
                      clientVersion: "1.0.0")
        ]

        XCTAssertEqual(userAgents, expected)
    }

    func testIOSUserAgents() throws {
        let uaStrings = [
            // New User Agent Implementation
            "Element/1.9.8 (iPhone X; iOS 15.2; Scale/3.00)",
            "Element/1.9.9 (iPhone XS; iOS 15.5; Scale/3.00)",
            // Legacy User Agent Implementation
            "Element/1.8.21 (iPhone; iOS 15.0; Scale/2.00)",
            "Element/1.8.19 (iPhone; iOS 15.2; Scale/3.00)"
        ]
        let userAgents = uaStrings.map { UserAgentParser.parse($0) }

        let expected = [
            UserAgent(deviceType: .mobile,
                      deviceModel: "iPhone X",
                      deviceOS: "iOS 15.2",
                      clientName: "Element",
                      clientVersion: "1.9.8"),
            UserAgent(deviceType: .mobile,
                      deviceModel: "iPhone XS",
                      deviceOS: "iOS 15.5",
                      clientName: "Element",
                      clientVersion: "1.9.9"),
            UserAgent(deviceType: .mobile,
                      deviceModel: "iPhone",
                      deviceOS: "iOS 15.0",
                      clientName: "Element",
                      clientVersion: "1.8.21"),
            UserAgent(deviceType: .mobile,
                      deviceModel: "iPhone",
                      deviceOS: "iOS 15.2",
                      clientName: "Element",
                      clientVersion: "1.8.19")
        ]

        XCTAssertEqual(userAgents, expected)
    }

    func testDesktopUserAgents() {
        let uaStrings = [
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) ElementNightly/2022091301 Chrome/104.0.5112.102 Electron/20.1.1 Safari/537.36"
        ]
        let userAgents = uaStrings.map { UserAgentParser.parse($0) }

        let expected = [
            UserAgent(deviceType: .desktop,
                      deviceModel: "Macintosh",
                      deviceOS: "Intel Mac OS X 10_15_7",
                      clientName: "Mozilla",
                      clientVersion: "5.0")
        ]

        XCTAssertEqual(userAgents, expected)
    }

    func testWebUserAgents() throws {
        let uaStrings = [
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36"
        ]
        let userAgents = uaStrings.map { UserAgentParser.parse($0) }

        let expected = [
            UserAgent(deviceType: .web,
                      deviceModel: "Macintosh",
                      deviceOS: "Intel Mac OS X 10_15_7",
                      clientName: "Mozilla",
                      clientVersion: "5.0")
        ]

        XCTAssertEqual(userAgents, expected)
    }

}
