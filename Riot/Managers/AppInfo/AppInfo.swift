// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
