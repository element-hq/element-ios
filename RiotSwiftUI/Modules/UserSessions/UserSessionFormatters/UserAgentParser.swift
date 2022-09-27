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
    let deviceOSVersion: String?
    let clientName: String?
    let clientVersion: String?
}

class UserAgentParser {

    static func parse(_ userAgent: String) -> UserAgent? {
        guard !userAgent.isEmpty else {
            return nil
        }
        // Expected user agent format: "Element/1.9.7 (iPhone XS Max; iOS 15.5; Scale/3)"
        return nil
    }

}
