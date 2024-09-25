/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

/// Secure backup banner user preferences.
@objcMembers
final class SecureBackupBannerPreferences: NSObject {
    
    // MARK: - Constants
    
    private enum UserDefaultsKeys {
        static let hideSetupBanner = "SecureBackupBannerPreferencesHideSetupBanner"
    }
    
    static let shared = SecureBackupBannerPreferences()
    
    // MARK: - Properties
    
    // MARK: - Public
    
    /// Remember to hide key backup setup banner.
    var hideSetupBanner: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UserDefaultsKeys.hideSetupBanner)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.hideSetupBanner)
        }
    }
    
    /// Reset key backup banner preferences to default values
    func reset() {
        self.hideSetupBanner = false
    }
}
