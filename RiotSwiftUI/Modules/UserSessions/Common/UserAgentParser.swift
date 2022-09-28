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

import Foundation

struct UserAgent {
    let deviceType: DeviceType
    let deviceModel: String?
    let deviceOS: String?
    let clientName: String?
    let clientVersion: String?

    static let unknown = UserAgent(deviceType: .unknown,
                                   deviceModel: nil,
                                   deviceOS: nil,
                                   clientName: nil,
                                   clientVersion: nil)
}

extension UserAgent: Equatable { }

enum UserAgentParser {
    private enum Constants {
        static let deviceInfoRegexPattern = "\\((?:[^)(]+|\\((?:[^)(]+|\\([^)(]*\\))*\\))*\\)"

        static let androidKeyword = "; MatrixAndroidSdk2"
        static let iosKeyword = "; iOS "
        static let desktopKeyword = " Electron/"
        static let webKeyword = "Mozilla/"
    }

    static func parse(_ userAgent: String) -> UserAgent {
        if userAgent.vc_caseInsensitiveContains(Constants.androidKeyword) {
            return parseAndroid(userAgent)
        } else if userAgent.vc_caseInsensitiveContains(Constants.iosKeyword) {
            return parseIOS(userAgent)
        } else if userAgent.vc_caseInsensitiveContains(Constants.desktopKeyword) {
            return parseDesktop(userAgent)
        } else if userAgent.vc_caseInsensitiveContains(Constants.webKeyword) {
            return parseWeb(userAgent)
        }
        return .unknown
    }

    // Legacy:  Element/1.0.0 (Linux; U; Android 6.0.1; SM-A510F Build/MMB29; Flavour GPlay; MatrixAndroidSdk2 1.0)
    // New:     Element dbg/1.5.0-dev (Xiaomi Mi 9T; Android 11; RKQ1.200826.002 test-keys; Flavour GooglePlay; MatrixAndroidSdk2 1.5.0)
    private static func parseAndroid(_ userAgent: String) -> UserAgent {
        var deviceModel: String?
        var deviceOS: String?
        var clientName: String?
        var clientVersion: String?

        let (beforeSlash, afterSlash) = userAgent.splitByFirst("/")
        clientName = beforeSlash
        if let afterSlash = afterSlash {
            let (beforeSpace, afterSpace) = afterSlash.splitByFirst(" ")
            clientVersion = beforeSpace
            if let afterSpace = afterSpace {
                if let deviceInfo = findFirstDeviceInfo(in: afterSpace) {
                    let deviceInfoComponents = deviceInfo.components(separatedBy: "; ")
                    let isLegacy = deviceInfoComponents[safe: 0] == "Linux"
                    if isLegacy {
                        // find the segment starting with "Android"
                        if let osSegmentIndex = deviceInfoComponents.firstIndex(where: { $0.hasPrefix("Android") }) {
                            deviceOS = deviceInfoComponents[safe: osSegmentIndex]
                            deviceModel = deviceInfoComponents[safe: osSegmentIndex + 1]
                        }
                    } else {
                        deviceModel = deviceInfoComponents[safe: 0]
                        deviceOS = deviceInfoComponents[safe: 1]
                    }
                }
            }
        }

        return UserAgent(deviceType: .mobile,
                         deviceModel: deviceModel,
                         deviceOS: deviceOS,
                         clientName: clientName,
                         clientVersion: clientVersion)
    }

    // Legacy:  Riot/1.8.21 (iPhone; iOS 15.2; Scale/3.00)
    // New:     Riot/1.8.21 (iPhone X; iOS 15.2; Scale/3.00)
    private static func parseIOS(_ userAgent: String) -> UserAgent {
        var deviceModel: String?
        var deviceOS: String?
        var clientName: String?
        var clientVersion: String?

        let (beforeSlash, afterSlash) = userAgent.splitByFirst("/")
        clientName = beforeSlash
        if let afterSlash = afterSlash {
            let (beforeSpace, afterSpace) = afterSlash.splitByFirst(" ")
            clientVersion = beforeSpace
            if let afterSpace = afterSpace {
                if let deviceInfo = findFirstDeviceInfo(in: afterSpace) {
                    let deviceInfoComponents = deviceInfo.components(separatedBy: "; ")
                    deviceModel = deviceInfoComponents[safe: 0]
                    deviceOS = deviceInfoComponents[safe: 1]
                }
            }
        }

        return UserAgent(deviceType: .mobile,
                         deviceModel: deviceModel,
                         deviceOS: deviceOS,
                         clientName: clientName,
                         clientVersion: clientVersion)
    }

    // Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) ElementNightly/2022091301 Chrome/104.0.5112.102 Electron/20.1.1 Safari/537.36
    private static func parseDesktop(_ userAgent: String) -> UserAgent {
        var deviceModel: String?
        var deviceOS: String?
        var clientName: String?
        var clientVersion: String?

        let (beforeSlash, afterSlash) = userAgent.splitByFirst("/")
        clientName = beforeSlash
        if let afterSlash = afterSlash {
            let (beforeSpace, afterSpace) = afterSlash.splitByFirst(" ")
            clientVersion = beforeSpace
            if let afterSpace = afterSpace {
                if let deviceInfo = findFirstDeviceInfo(in: afterSpace) {
                    let deviceInfoComponents = deviceInfo.components(separatedBy: "; ")
                    deviceModel = deviceInfoComponents[safe: 0]
                    deviceOS = deviceInfoComponents[safe: 1]
                }
            }
        }

        return UserAgent(deviceType: .desktop,
                         deviceModel: deviceModel,
                         deviceOS: deviceOS,
                         clientName: clientName,
                         clientVersion: clientVersion)
    }

    // Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36
    private static func parseWeb(_ userAgent: String) -> UserAgent {
        var deviceModel: String?
        var deviceOS: String?
        var clientName: String?
        var clientVersion: String?

        let (beforeSlash, afterSlash) = userAgent.splitByFirst("/")
        clientName = beforeSlash
        if let afterSlash = afterSlash {
            let (beforeSpace, afterSpace) = afterSlash.splitByFirst(" ")
            clientVersion = beforeSpace
            if let afterSpace = afterSpace {
                if let deviceInfo = findFirstDeviceInfo(in: afterSpace) {
                    let deviceInfoComponents = deviceInfo.components(separatedBy: "; ")
                    deviceModel = deviceInfoComponents[safe: 0]
                    deviceOS = deviceInfoComponents[safe: 1]
                }
            }
        }

        return UserAgent(deviceType: .web,
                         deviceModel: deviceModel,
                         deviceOS: deviceOS,
                         clientName: clientName,
                         clientVersion: clientVersion)
    }

    private static func findFirstDeviceInfo(in string: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: Constants.deviceInfoRegexPattern,
                                                options: .caseInsensitive)
            var range = regex.rangeOfFirstMatch(in: string, range: NSRange(string.startIndex..., in: string))
            if range.location != NSNotFound {
                range.location += 1
                range.length -= 2
                return string[range]
            }
            return nil
        } catch {
            MXLog.debug("[UserAgentParser] Couldn't create regex: \(error)")
            return nil
        }
    }
}

private extension String {
    subscript(_ range: NSRange) -> String {
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(startIndex, offsetBy: range.upperBound)
        let subString = self[start..<end]
        return String(subString)
    }

    func splitByFirst(_ delimiter: Character) -> (String?, String?) {
        guard let delimiterIndex = firstIndex(of: delimiter) else {
            return (nil, nil)
        }
        let before = String(prefix(upTo: delimiterIndex))
        let after = String(suffix(from: index(after: delimiterIndex)))
        return (before, after)
    }

    func trimmingWhitespaces() -> String {
        trimmingCharacters(in: .whitespaces)
    }
}
