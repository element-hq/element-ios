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

/// Store Riot specific app settings.
@objcMembers
final class RiotSettings: NSObject {
    
    // MARK: - Constants
    
    private enum UserDefaultsKeys {
        static let homeserverUrlString = "homeserverurl"
        static let identityServerUrlString = "identityserverurl"
        static let enableCrashReport = "enableCrashReport"
        static let enableRageShake = "enableRageShake"
        static let createConferenceCallsWithJitsi = "createConferenceCallsWithJitsi"
        static let userInterfaceTheme = "userInterfaceTheme"
        static let notificationsShowDecryptedContent = "showDecryptedContent"
        static let pinRoomsWithMissedNotifications = "pinRoomsWithMissedNotif"
        static let pinRoomsWithUnreadMessages = "pinRoomsWithUnread"
        static let allowStunServerFallback = "allowStunServerFallback"
        static let hideVerifyThisSessionAlert = "hideVerifyThisSessionAlert"
        static let hideReviewSessionsAlert = "hideReviewSessionsAlert"
        static let matrixApps = "matrixApps"
        static let showNSFWPublicRooms = "showNSFWPublicRooms"
        static let settingsScreenShowChangePassword = "settingsScreenShowChangePassword"
        static let settingsScreenShowInviteFriends = "settingsScreenShowInviteFriends"
        static let settingsScreenShowEnableStunServerFallback = "settingsScreenShowEnableStunServerFallback"
        static let settingsSecurityScreenShowSessions = "settingsSecurityScreenShowSessions"
        static let settingsSecurityScreenShowSetupBackup = "settingsSecurityScreenShowSetupBackup"
        static let settingsSecurityScreenShowRestoreBackup = "settingsSecurityScreenShowRestoreBackup"
        static let settingsSecurityScreenShowDeleteBackup = "settingsSecurityScreenShowDeleteBackup"
        static let settingsSecurityScreenShowCryptographyInfo = "settingsSecurityScreenShowCryptographyInfo"
        static let settingsSecurityScreenShowCryptographyExport = "settingsSecurityScreenShowCryptographyExport"
        static let settingsSecurityScreenShowAdvancedUnverifiedDevices = "settingsSecurityScreenShowAdvancedBlacklistUnverifiedDevices"
        static let roomCreationScreenAllowEncryptionConfiguration = "roomCreationScreenAllowEncryptionConfiguration"
        static let roomCreationScreenRoomIsEncrypted = "roomCreationScreenRoomIsEncrypted"
        static let roomCreationScreenAllowRoomTypeConfiguration = "roomCreationScreenAllowRoomTypeConfiguration"
        static let roomCreationScreenRoomIsPublic = "roomCreationScreenRoomIsPublic"
        static let allowInviteExernalUsers = "allowInviteExernalUsers"
    }
    
    static let shared = RiotSettings()
    
    /// UserDefaults to be used on reads and writes.
    private lazy var defaults: UserDefaults = {
        guard let userDefaults = UserDefaults(suiteName: BuildSettings.applicationGroupIdentifier) else {
            fatalError("[RiotSettings] Fail to load shared UserDefaults")
        }
        return userDefaults
    }()
    
    // MARK: - Public
    
    func reset() {
        defaults.removeObject(forKey: UserDefaultsKeys.settingsScreenShowChangePassword)
        defaults.removeObject(forKey: UserDefaultsKeys.settingsScreenShowInviteFriends)
        defaults.removeObject(forKey: UserDefaultsKeys.settingsScreenShowEnableStunServerFallback)
        defaults.removeObject(forKey: UserDefaultsKeys.settingsSecurityScreenShowSessions)
        defaults.removeObject(forKey: UserDefaultsKeys.settingsSecurityScreenShowSetupBackup)
        defaults.removeObject(forKey: UserDefaultsKeys.settingsSecurityScreenShowRestoreBackup)
        defaults.removeObject(forKey: UserDefaultsKeys.settingsSecurityScreenShowDeleteBackup)
        defaults.removeObject(forKey: UserDefaultsKeys.settingsSecurityScreenShowCryptographyInfo)
        defaults.removeObject(forKey: UserDefaultsKeys.settingsSecurityScreenShowCryptographyExport)
        defaults.removeObject(forKey: UserDefaultsKeys.settingsSecurityScreenShowAdvancedUnverifiedDevices)
        defaults.removeObject(forKey: UserDefaultsKeys.allowInviteExernalUsers)
    }
    
    // MARK: Servers
    
    var homeserverUrlString: String {
        get {
            return defaults.string(forKey: UserDefaultsKeys.homeserverUrlString) ?? BuildSettings.serverConfigDefaultHomeserverUrlString
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.homeserverUrlString)
        }
    }
    
    var identityServerUrlString: String {
        get {
            return defaults.string(forKey: UserDefaultsKeys.identityServerUrlString) ?? BuildSettings.serverConfigDefaultIdentityServerUrlString
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.identityServerUrlString)
        }
    }
    
    // MARK: Notifications
    
    /// Indicate if `showDecryptedContentInNotifications` settings has been set once.
    var isShowDecryptedContentInNotificationsHasBeenSetOnce: Bool {
        return defaults.object(forKey: UserDefaultsKeys.notificationsShowDecryptedContent) != nil
    }
    
    /// Indicate if UserDefaults suite has been migrated once.
    var isUserDefaultsMigrated: Bool {
        return defaults.object(forKey: UserDefaultsKeys.notificationsShowDecryptedContent) != nil
    }
    
    func migrate() {
        //  read all values from standard
        let dictionary = UserDefaults.standard.dictionaryRepresentation()
        
        //  write values to suite
        //  remove redundant values from standard
        for (key, value) in dictionary {
            defaults.set(value, forKey: key)
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    /// Indicate if encrypted messages content should be displayed in notifications.
    var showDecryptedContentInNotifications: Bool {
        get {
            return defaults.bool(forKey: UserDefaultsKeys.notificationsShowDecryptedContent)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.notificationsShowDecryptedContent)
        }
    }
    
    /// Indicate if rooms with missed notifications should be displayed first on home screen.
    var pinRoomsWithMissedNotificationsOnHome: Bool {
        get {
            return defaults.bool(forKey: UserDefaultsKeys.pinRoomsWithMissedNotifications)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.pinRoomsWithMissedNotifications)
        }
    }
    
    /// Indicate if rooms with unread messages should be displayed first on home screen.
    var pinRoomsWithUnreadMessagesOnHome: Bool {
        get {
            return defaults.bool(forKey: UserDefaultsKeys.pinRoomsWithUnreadMessages)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.pinRoomsWithUnreadMessages)
        }
    }
    
    /// Indicate to show Not Safe For Work public rooms.
    var showNSFWPublicRooms: Bool {
        get {
            return defaults.bool(forKey: UserDefaultsKeys.showNSFWPublicRooms)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.showNSFWPublicRooms)
        }
    }
    
    // MARK: User interface
    
    var userInterfaceTheme: String? {
        get {
            return defaults.string(forKey: UserDefaultsKeys.userInterfaceTheme)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.userInterfaceTheme)
        }
    }
    
    // MARK: Other
    
    /// Indicate if `enableCrashReport` settings has been set once.
    var isEnableCrashReportHasBeenSetOnce: Bool {
        return defaults.object(forKey: UserDefaultsKeys.enableCrashReport) != nil
    }
    
    var enableCrashReport: Bool {
        get {
            return defaults.bool(forKey: UserDefaultsKeys.enableCrashReport)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.enableCrashReport)
        }
    }
    
    var enableRageShake: Bool {
        get {
            return defaults.bool(forKey: UserDefaultsKeys.enableRageShake)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.enableRageShake)
        }
    }
    
    // MARK: Labs
    
    var createConferenceCallsWithJitsi: Bool {
        get {
            return defaults.bool(forKey: UserDefaultsKeys.createConferenceCallsWithJitsi)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.createConferenceCallsWithJitsi)
        }
    }

    // MARK: Calls

    /// Indicate if `allowStunServerFallback` settings has been set once.
    var isAllowStunServerFallbackHasBeenSetOnce: Bool {
        return defaults.object(forKey: UserDefaultsKeys.allowStunServerFallback) != nil
    }

    var allowStunServerFallback: Bool {
        get {
            return defaults.bool(forKey: UserDefaultsKeys.allowStunServerFallback)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.allowStunServerFallback)
        }
    }
    
    // MARK: Key verification
    
    var hideVerifyThisSessionAlert: Bool {
        get {
            return defaults.bool(forKey: UserDefaultsKeys.hideVerifyThisSessionAlert)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.hideVerifyThisSessionAlert)
        }
    }
    
    var hideReviewSessionsAlert: Bool {
        get {
            return defaults.bool(forKey: UserDefaultsKeys.hideReviewSessionsAlert)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.hideReviewSessionsAlert)
        }
    }
    
    var matrixApps: Bool {
        get {
            return defaults.bool(forKey: UserDefaultsKeys.matrixApps)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.matrixApps)
        }
    }
    
    // MARK: - Room Creation Screen

    var roomCreationScreenAllowEncryptionConfiguration: Bool {
        get {
            guard defaults.object(forKey: UserDefaultsKeys.roomCreationScreenAllowEncryptionConfiguration) != nil else {
                return BuildSettings.roomCreationScreenAllowEncryptionConfiguration
            }
            return defaults.bool(forKey: UserDefaultsKeys.roomCreationScreenAllowEncryptionConfiguration)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.roomCreationScreenAllowEncryptionConfiguration)
        }
    }
    var roomCreationScreenRoomIsEncrypted: Bool {
        get {
            guard defaults.object(forKey: UserDefaultsKeys.roomCreationScreenRoomIsEncrypted) != nil else {
                return BuildSettings.roomCreationScreenRoomIsEncrypted
            }
            return defaults.bool(forKey: UserDefaultsKeys.roomCreationScreenRoomIsEncrypted)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.roomCreationScreenRoomIsEncrypted)
        }
    }
    var roomCreationScreenAllowRoomTypeConfiguration: Bool {
        get {
            guard defaults.object(forKey: UserDefaultsKeys.roomCreationScreenAllowRoomTypeConfiguration) != nil else {
                return BuildSettings.roomCreationScreenAllowRoomTypeConfiguration
            }
            return defaults.bool(forKey: UserDefaultsKeys.roomCreationScreenAllowRoomTypeConfiguration)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.roomCreationScreenAllowRoomTypeConfiguration)
        }
    }
    var roomCreationScreenRoomIsPublic: Bool {
        get {
            guard defaults.object(forKey: UserDefaultsKeys.roomCreationScreenRoomIsPublic) != nil else {
                return BuildSettings.roomCreationScreenRoomIsPublic
            }
            return defaults.bool(forKey: UserDefaultsKeys.roomCreationScreenRoomIsPublic)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.roomCreationScreenRoomIsPublic)
        }
    }

    // MARK: Features

    var allowInviteExernalUsers: Bool {
        get {
            guard defaults.object(forKey: UserDefaultsKeys.allowInviteExernalUsers) != nil else {
                return BuildSettings.allowInviteExernalUsers
            }
            return defaults.bool(forKey: UserDefaultsKeys.allowInviteExernalUsers)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.allowInviteExernalUsers)
        }
    }

    // MARK: General Settings
    
    var settingsScreenShowChangePassword: Bool {
        get {
            guard defaults.object(forKey: UserDefaultsKeys.settingsScreenShowChangePassword) != nil else {
                return BuildSettings.settingsScreenShowChangePassword
            }
            return defaults.bool(forKey: UserDefaultsKeys.settingsScreenShowChangePassword)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.settingsScreenShowChangePassword)
        }
    }
    var settingsScreenShowInviteFriends: Bool {
        get {
            guard defaults.object(forKey: UserDefaultsKeys.settingsScreenShowInviteFriends) != nil else {
                return BuildSettings.settingsScreenShowInviteFriends
            }
            return defaults.bool(forKey: UserDefaultsKeys.settingsScreenShowInviteFriends)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.settingsScreenShowInviteFriends)
        }
    }
    var settingsScreenShowEnableStunServerFallback: Bool {
        get {
            guard defaults.object(forKey: UserDefaultsKeys.settingsScreenShowInviteFriends) != nil else {
                return BuildSettings.settingsScreenShowEnableStunServerFallback
            }
            return defaults.bool(forKey: UserDefaultsKeys.settingsScreenShowEnableStunServerFallback)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.settingsScreenShowEnableStunServerFallback)
        }
    }
    var settingsSecurityScreenShowSessions: Bool {
        get {
            guard defaults.object(forKey: UserDefaultsKeys.settingsSecurityScreenShowSessions) != nil else {
                return BuildSettings.settingsSecurityScreenShowSessions
            }
            return defaults.bool(forKey: UserDefaultsKeys.settingsSecurityScreenShowSessions)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.settingsSecurityScreenShowSessions)
        }
    }
    var settingsSecurityScreenShowSetupBackup: Bool {
        get {
            guard defaults.object(forKey: UserDefaultsKeys.settingsSecurityScreenShowSetupBackup) != nil else {
                return BuildSettings.settingsSecurityScreenShowSetupBackup
            }
            return defaults.bool(forKey: UserDefaultsKeys.settingsSecurityScreenShowSetupBackup)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.settingsSecurityScreenShowSetupBackup)
        }
    }
    var settingsSecurityScreenShowRestoreBackup: Bool {
        get {
            guard defaults.object(forKey: UserDefaultsKeys.settingsSecurityScreenShowRestoreBackup) != nil else {
                return BuildSettings.settingsSecurityScreenShowRestoreBackup
            }
            return defaults.bool(forKey: UserDefaultsKeys.settingsSecurityScreenShowRestoreBackup)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.settingsSecurityScreenShowRestoreBackup)
        }
    }
    var settingsSecurityScreenShowDeleteBackup: Bool {
        get {
            guard defaults.object(forKey: UserDefaultsKeys.settingsSecurityScreenShowDeleteBackup) != nil else {
                return BuildSettings.settingsSecurityScreenShowDeleteBackup
            }
            return defaults.bool(forKey: UserDefaultsKeys.settingsSecurityScreenShowDeleteBackup)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.settingsSecurityScreenShowDeleteBackup)
        }
    }
    var settingsSecurityScreenShowCryptographyInfo: Bool {
        get {
            guard defaults.object(forKey: UserDefaultsKeys.settingsSecurityScreenShowCryptographyInfo) != nil else {
                return BuildSettings.settingsSecurityScreenShowCryptographyInfo
            }
            return defaults.bool(forKey: UserDefaultsKeys.settingsSecurityScreenShowCryptographyInfo)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.settingsSecurityScreenShowCryptographyInfo)
        }
    }
    var settingsSecurityScreenShowCryptographyExport: Bool {
        get {
            guard defaults.object(forKey: UserDefaultsKeys.settingsSecurityScreenShowCryptographyExport) != nil else {
                return BuildSettings.settingsSecurityScreenShowCryptographyExport
            }
            return defaults.bool(forKey: UserDefaultsKeys.settingsSecurityScreenShowCryptographyExport)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.settingsSecurityScreenShowCryptographyExport)
        }
    }
    var settingsSecurityScreenShowAdvancedUnverifiedDevices: Bool {
        get {
            guard defaults.object(forKey: UserDefaultsKeys.settingsSecurityScreenShowAdvancedUnverifiedDevices) != nil else {
                return BuildSettings.settingsSecurityScreenShowAdvancedUnverifiedDevices
            }
            return defaults.bool(forKey: UserDefaultsKeys.settingsSecurityScreenShowAdvancedUnverifiedDevices)
        } set {
            defaults.set(newValue, forKey: UserDefaultsKeys.settingsSecurityScreenShowAdvancedUnverifiedDevices)
        }
    }
}
