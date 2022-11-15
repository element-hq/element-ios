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

@testable import RiotSwiftUI
import XCTest

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
            "Element/1.9.7 (iPad Pro (12.9-inch) (3rd generation); iOS 15.5; Scale/3.00)",
            // Legacy User Agent Implementation
            "Element/1.8.21 (iPhone; iOS 15.0; Scale/2.00)",
            "Element/1.8.19 (iPhone; iOS 15.2; Scale/3.00)",
            // Simulator User Agent
            "Element/1.9.7 (Simulator (iPhone 13 Pro Max); iOS 15.5; Scale/3.00)"
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
                      deviceModel: "iPad Pro (12.9-inch) (3rd generation)",
                      deviceOS: "iOS 15.5",
                      clientName: "Element",
                      clientVersion: "1.9.7"),
            UserAgent(deviceType: .mobile,
                      deviceModel: "iPhone",
                      deviceOS: "iOS 15.0",
                      clientName: "Element",
                      clientVersion: "1.8.21"),
            UserAgent(deviceType: .mobile,
                      deviceModel: "iPhone",
                      deviceOS: "iOS 15.2",
                      clientName: "Element",
                      clientVersion: "1.8.19"),
            UserAgent(deviceType: .mobile,
                      deviceModel: "Simulator (iPhone 13 Pro Max)",
                      deviceOS: "iOS 15.5",
                      clientName: "Element",
                      clientVersion: "1.9.7")
        ]

        XCTAssertEqual(userAgents, expected)
    }

    func testDesktopUserAgents() {
        let uaStrings = [
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) ElementNightly/2022091301 Chrome/104.0.5112.102 Electron/20.1.1 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0) AppleWebKit/537.36 (KHTML, like Gecko) ElementNightly/2022091301 Chrome/104.0.5112.102 Electron/20.1.1 Safari/537.36"
        ]
        let userAgents = uaStrings.map { UserAgentParser.parse($0) }

        let expected = [
            UserAgent(deviceType: .desktop,
                      deviceModel: nil,
                      deviceOS: "macOS",
                      clientName: "Electron",
                      clientVersion: "20.1.1"),
            UserAgent(deviceType: .desktop,
                      deviceModel: nil,
                      deviceOS: "Windows",
                      clientName: "Electron",
                      clientVersion: "20.1.1")
        ]

        XCTAssertEqual(userAgents, expected)
    }

    func testWebUserAgents() throws {
        let uaStrings = [
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.102 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.102 Safari/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:39.0) Gecko/20100101 Firefox/39.0",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/600.3.18 (KHTML, like Gecko) Version/8.0.3 Safari/600.3.18",
            "Mozilla/5.0 (Linux; Android 9; SM-G973U Build/PPR1.180610.011) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Mobile Safari/537.36"
        ]
        let userAgents = uaStrings.map { UserAgentParser.parse($0) }

        let expected = [
            UserAgent(deviceType: .web,
                      deviceModel: nil,
                      deviceOS: "macOS",
                      clientName: "Chrome",
                      clientVersion: "104.0.5112.102"),
            UserAgent(deviceType: .web,
                      deviceModel: nil,
                      deviceOS: "Windows",
                      clientName: "Chrome",
                      clientVersion: "104.0.5112.102"),
            UserAgent(deviceType: .web,
                      deviceModel: nil,
                      deviceOS: "macOS",
                      clientName: "Firefox",
                      clientVersion: "39.0"),
            UserAgent(deviceType: .web,
                      deviceModel: nil,
                      deviceOS: "macOS",
                      clientName: "Safari",
                      clientVersion: "8.0.3"),
            UserAgent(deviceType: .web,
                      deviceModel: nil,
                      deviceOS: "Android 9",
                      clientName: "Chrome",
                      clientVersion: "69.0.3497.100")
        ]

        XCTAssertEqual(userAgents, expected)
    }

    func testInvalidUserAgents() throws {
        let uaStrings = [
            "Element (iPhone X; OS 15.2; 3.00)",
            "Element/1.9.9; iOS",
            "Element/1.9.7 Android",
            "some random string",
            "Element/1.9.9; iOS "
        ]
        let userAgents = uaStrings.map { UserAgentParser.parse($0) }

        let expected = [
            .unknown,
            .unknown,
            .unknown,
            .unknown,
            UserAgent(deviceType: .mobile,
                      deviceModel: nil,
                      deviceOS: nil,
                      clientName: "Element",
                      clientVersion: "1.9.9;")
        ]

        XCTAssertEqual(userAgents, expected)
    }
}
