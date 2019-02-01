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

/// Key backup banner user preferences.
@objcMembers
final class KeyBackupBannerPreferences: NSObject {
    
    // MARK: - Constants
    
    private enum UserDefaultsKeys {
        static let hideSetupBanner = "KeyBackupBannerPreferencesHideSetupBanner"
        static let hiddenRecoverBannerKeyBackupVersions = "KeyBackupBannerPreferencesHiddenRecoverBannerKeyBackupVersions"
    }
    
    static let shared = KeyBackupBannerPreferences()
    
    // MARK: - Properties
    private var hiddenRecoverBannerKeyBackupVersions: [String] {
        get {
            return UserDefaults.standard.stringArray(forKey: UserDefaultsKeys.hiddenRecoverBannerKeyBackupVersions) ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.hiddenRecoverBannerKeyBackupVersions)
        }
    }
    
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
    
    /// Remember to hide key backup recover banner for specific key backup version.
    ///
    /// - Parameter keyBackupVersion: Key backup version recover banner to hide.
    func hideRecoverBanner(for keyBackupVersion: String) {
        guard self.hiddenRecoverBannerKeyBackupVersions.contains(keyBackupVersion) == false else {
            return
        }
        self.hiddenRecoverBannerKeyBackupVersions.append(keyBackupVersion)
    }
    
    /// Check if key backup recover banner should be hidden for key backup version.
    ///
    /// - Parameter keyBackupVersion: Key backup version to check.
    /// - Returns: true if recover banner should be hidden.
    func isRecoverBannerHidden(for keyBackupVersion: String) -> Bool {
        return self.hiddenRecoverBannerKeyBackupVersions.contains(keyBackupVersion)
    }
    
    /// Reset key backup banner preferences to default values
    func reset() {
        self.hideSetupBanner = false
        self.hiddenRecoverBannerKeyBackupVersions = []
    }
}
