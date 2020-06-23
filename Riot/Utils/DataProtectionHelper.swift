/*
Copyright 2020 New Vector Ltd

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import Foundation

final class DataProtectionHelper {
    
    static func isDeviceInRebootedAndLockedState(appGroupIdentifier: String? = nil) -> Bool {
        do {
            let str = String.unique
            let dummyData = str.data(using: .utf8)!

            var url: URL!
            if let identifier = appGroupIdentifier {
                let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
                if containerURL == nil {
                    url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                } else {
                    url = containerURL?.appendingPathComponent("Library/Caches")
                }
            } else {
                url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            }

            url = url.appendingPathComponent(String.unique)

            try dummyData.write(to: url, options: .completeFileProtectionUntilFirstUserAuthentication)
            let readData = try Data(contentsOf: url)
            let readString = String(data: readData, encoding: .utf8)
            try FileManager.default.removeItem(at: url)
            if readString != str {
                return true
            }
        } catch {
            return true
        }
        return false
    }
    
}

extension String {
    
    /// Returns a globally unique string
    static var unique: String {
        return ProcessInfo.processInfo.globallyUniqueString
    }
    
}
