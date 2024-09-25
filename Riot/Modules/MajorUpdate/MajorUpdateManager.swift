/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

/// `MajorUpdateManager` is used to indicate if a major update alert should be displayed.
@objcMembers
final public class MajorUpdateManager: NSObject {
    
    // MARK: - Constants
    
    private enum Constants {
        static var lastMajorAppVersion = AppVersion(bundleShortVersion: "1.0.0", bundleVersion: "0")
        static var learnMoreStringURL = "https://element.io/previously-riot"
    }
    
    // MARK: - Properties
    
    var shouldShowMajorUpdate: Bool {
        guard let lastUsedAppVersion = AppVersion.lastUsed else {
            MXLog.debug("[MajorUpdateManager] shouldShowMajorUpdate: Unknown previous version")
            return false
        }
        
        let shouldShowMajorUpdate = (lastUsedAppVersion.compare(Constants.lastMajorAppVersion) == .orderedAscending)
        MXLog.debug("[MajorUpdateManager] shouldShowMajorUpdate: \(shouldShowMajorUpdate). AppVersion.lastUsed: \(lastUsedAppVersion). lastMajorAppVersion: \(Constants.lastMajorAppVersion)")
        
        return shouldShowMajorUpdate
    }
    
    var learnMoreURL: URL {
        guard let url = URL(string: Constants.learnMoreStringURL) else {
            fatalError("[MajorUpdateManager] learn more URL should be valid")
        }
        return url
    }
}
