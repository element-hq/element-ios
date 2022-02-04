// 
// Copyright 2021 New Vector Ltd
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

/// Used to handle the application information
@objcMembers
final class AppInfo: NSObject {
    
    // MARK: - Constants
    
    /// Current application information
    static var current: AppInfo {
        return AppInfo(displayName: self.bundleDisplayName,
                       appVersion: AppVersion.current,
                       buildInfo: BuildInfo())
    }
    
    // MARK: - Properties
    
    /// App display name
    let displayName: String
    
    /// Current app version
    let appVersion: AppVersion?
    
    /// Compilation build info
    let buildInfo: BuildInfo
    
    // MARK: - Setup
    
    init(displayName: String,
         appVersion: AppVersion?,
         buildInfo: BuildInfo) {
        self.displayName = displayName
        self.appVersion = appVersion
        self.buildInfo = buildInfo
    }
    
    private static var bundleDisplayName: String {
        guard let bundleDisplayName = Bundle.app.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String else {
            fatalError("CFBundleDisplayName should be defined")
        }
        return bundleDisplayName
    }
}
