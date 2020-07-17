/*
 Copyright 2018 New Vector Ltd
 
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
