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
    
    public enum UserDefaultsKeys {
        static let enableAnalytics = "enableAnalytics"
        static let matomoAnalytics = "enableCrashReport"
        static let notificationsShowDecryptedContent = "showDecryptedContent"
        static let allowStunServerFallback = "allowStunServerFallback"
        static let pinRoomsWithMissedNotificationsOnHome = "pinRoomsWithMissedNotif"
        static let pinRoomsWithUnreadMessagesOnHome = "pinRoomsWithUnread"
        static let showAllRoomsInHomeSpace = "showAllRoomsInHomeSpace"
        static let enableUISIAutoReporting = "enableUISIAutoReporting"
        static let enableLiveLocationSharing = "enableLiveLocationSharing"
        static let showIPAddressesInSessionsManager = "showIPAddressesInSessionsManager"
    }
    
    static let shared = RiotSettings()
    
    /// UserDefaults to be used on reads and writes.
    static var defaults: UserDefaults = {
        guard let userDefaults = UserDefaults(suiteName: BuildSettings.applicationGroupIdentifier) else {
            fatalError("[RiotSettings] Fail to load shared UserDefaults")
        }
        return userDefaults
    }()
    
    private override init() {
        super.init()
    }
    
    /// Indicate if UserDefaults suite has been migrated once.
    var isUserDefaultsMigrated: Bool {
        return RiotSettings.defaults.object(forKey: UserDefaultsKeys.notificationsShowDecryptedContent) != nil
    }
    
    func migrate() {
        //  read all values from standard
        let dictionary = UserDefaults.standard.dictionaryRepresentation()
        
        //  write values to suite
        //  remove redundant values from standard
        for (key, value) in dictionary {
            RiotSettings.defaults.set(value, forKey: key)
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    // MARK: Servers
    
    @UserDefault(key: "homeserverurl", defaultValue: BuildSettings.serverConfigDefaultHomeserverUrlString, storage: defaults)
    var homeserverUrlString
    
    @UserDefault(key: "identityserverurl", defaultValue: BuildSettings.serverConfigDefaultIdentityServerUrlString, storage: defaults)
    var identityServerUrlString
    
    // MARK: Notifications
    
    /// Indicate if `showDecryptedContentInNotifications` settings has been set once.
    var isShowDecryptedContentInNotificationsHasBeenSetOnce: Bool {
        return RiotSettings.defaults.object(forKey: UserDefaultsKeys.notificationsShowDecryptedContent) != nil
    }
    
    /// Indicate if notifications should be shown whilst the app is in the foreground.
    @UserDefault(key: "showInAppNotifications", defaultValue: true, storage: defaults)
    var showInAppNotifications
    
    /// Indicate if encrypted messages content should be displayed in notifications.
    @UserDefault(key: UserDefaultsKeys.notificationsShowDecryptedContent, defaultValue: false, storage: defaults)
    var showDecryptedContentInNotifications
    
    /// Indicate if rooms with missed notifications should be displayed first on home screen.
    @UserDefault(key: UserDefaultsKeys.pinRoomsWithMissedNotificationsOnHome, defaultValue: false, storage: defaults)
    var pinRoomsWithMissedNotificationsOnHome
    
    /// Indicate if rooms with unread messages should be displayed first on home screen.
    @UserDefault(key: UserDefaultsKeys.pinRoomsWithUnreadMessagesOnHome, defaultValue: false, storage: defaults)
    var pinRoomsWithUnreadMessagesOnHome
    
    /// Indicate to show Not Safe For Work public rooms.
    @UserDefault(key: "showNSFWPublicRooms", defaultValue: false, storage: defaults)
    var showNSFWPublicRooms
    
    // MARK: User interface
    
    @UserDefault<String?>(key: "userInterfaceTheme", defaultValue: nil, storage: defaults)
    var userInterfaceTheme
    
    // MARK: Analytics & Rageshakes
    
    /// Whether the user was previously shown the Matomo analytics prompt.
    var hasSeenAnalyticsPrompt: Bool {
        RiotSettings.defaults.object(forKey: UserDefaultsKeys.enableAnalytics) != nil
    }
    
    /// Whether the user has both seen the Matomo analytics prompt and declined it.
    var hasDeclinedMatomoAnalytics: Bool {
        RiotSettings.defaults.object(forKey: UserDefaultsKeys.matomoAnalytics) != nil && !RiotSettings.defaults.bool(forKey: UserDefaultsKeys.matomoAnalytics)
    }
    
    /// Whether the user previously accepted the Matomo analytics prompt.
    /// This allows these users to be shown a different prompt to explain the changes.
    var hasAcceptedMatomoAnalytics: Bool {
        RiotSettings.defaults.bool(forKey: UserDefaultsKeys.matomoAnalytics)
    }
    
    /// `true` when the user has opted in to send analytics.
    @UserDefault(key: UserDefaultsKeys.enableAnalytics, defaultValue: false, storage: defaults)
    var enableAnalytics
    
    /// Indicates if the device has already called identify for this session to PostHog.
    /// This is separate to `enableAnalytics` as logging out will leave analytics
    /// enabled but reset identification.
    @UserDefault(key: "isIdentifiedForAnalytics", defaultValue: false, storage: defaults)
    var isIdentifiedForAnalytics
    
    @UserDefault(key: "enableRageShake", defaultValue: false, storage: defaults)
    var enableRageShake
    
    // MARK: User
    
    /// A dictionary of dictionaries keyed by user ID for storage of the `UserSessionProperties` from any active `UserSession`s.
    @UserDefault(key: "userSessionProperties", defaultValue: [:], storage: defaults)
    var userSessionProperties: [String: [String: Any]]
    
    // MARK: Labs
    
    /// Indicates if CallKit ringing is enabled for group calls. This setting does not disable the CallKit integration for group calls, only relates to ringing.
    @UserDefault(key: "enableRingingForGroupCalls", defaultValue: false, storage: defaults)
    var enableRingingForGroupCalls
    
    /// Indicates if threads enabled in the timeline.
    @UserDefault(key: "enableThreads", defaultValue: false, storage: defaults)
    var enableThreads
    
    /// Indicates if threads should be forced enabled in the timeline.
    @UserDefault(key: "forceThreadsEnabled", defaultValue: true, storage: defaults)
    var forceThreadsEnabled

    /// Indicates if auto reporting of decryption errors is enabled
    @UserDefault(key: UserDefaultsKeys.enableUISIAutoReporting, defaultValue: BuildSettings.cryptoUISIAutoReportingEnabled, storage: defaults)
    var enableUISIAutoReporting
    
    /// Indicates if live location sharing is enabled
    @UserDefault(key: UserDefaultsKeys.enableLiveLocationSharing, defaultValue: false, storage: defaults)
    var enableLiveLocationSharing {
        didSet {
            NotificationCenter.default.post(name: RiotSettings.didUpdateLiveLocationSharingActivation, object: self)
        }
    }

    /// Flag indicating if the new session manager is enabled
    @UserDefault(key: "enableNewSessionManager", defaultValue: false, storage: defaults)
    var enableNewSessionManager

    /// Flag indicating if the new client information feature is enabled
    @UserDefault(key: "enableClientInformationFeature", defaultValue: false, storage: defaults)
    var enableClientInformationFeature

    /// Flag indicating if the wysiwyg composer feature is enabled
    @UserDefault(key: "enableWysiwygComposer", defaultValue: false, storage: defaults)
    var enableWysiwygComposer

    @UserDefault(key: "enableWysiwygTextFormatting", defaultValue: true, storage: defaults)
    var enableWysiwygTextFormatting
    
    /// Flag indicating if the IP addresses should be shown in the new device manager
    @UserDefault(key: UserDefaultsKeys.showIPAddressesInSessionsManager, defaultValue: false, storage: defaults)
    var showIPAddressesInSessionsManager
    
    /// Flag indicating if the voice broadcast feature is enabled
    @UserDefault(key: "enableVoiceBroadcast", defaultValue: false, storage: defaults)
    var enableVoiceBroadcast

    // MARK: Calls
    
    /// Indicate if `allowStunServerFallback` settings has been set once.
    var isAllowStunServerFallbackHasBeenSetOnce: Bool {
        return RiotSettings.defaults.object(forKey: UserDefaultsKeys.allowStunServerFallback) != nil
    }
    
    @UserDefault(key: UserDefaultsKeys.allowStunServerFallback, defaultValue: false, storage: defaults)
    var allowStunServerFallback
    
    // MARK: Key verification
    
    @UserDefault(key: "hideVerifyThisSessionAlert", defaultValue: false, storage: defaults)
    var hideVerifyThisSessionAlert
    
    @UserDefault(key: "matrixApps", defaultValue: false, storage: defaults)
    var matrixApps
    
    // MARK: -  Rooms Screen
    
    @UserDefault(key: "roomsAllowToJoinPublicRooms", defaultValue: BuildSettings.roomsAllowToJoinPublicRooms, storage: defaults)
    var roomsAllowToJoinPublicRooms
    
    @UserDefault(key: UserDefaultsKeys.showAllRoomsInHomeSpace, defaultValue: true, storage: defaults)
    var showAllRoomsInHomeSpace
    
    // MARK: - Room Screen
    
    @UserDefault(key: "roomScreenAllowVoIPForDirectRoom", defaultValue: BuildSettings.roomScreenAllowVoIPForDirectRoom, storage: defaults)
    var roomScreenAllowVoIPForDirectRoom
    
    @UserDefault(key: "roomScreenAllowVoIPForNonDirectRoom", defaultValue: BuildSettings.roomScreenAllowVoIPForNonDirectRoom, storage: defaults)
    var roomScreenAllowVoIPForNonDirectRoom
    
    @UserDefault(key: "roomScreenAllowCameraAction", defaultValue: BuildSettings.roomScreenAllowCameraAction, storage: defaults)
    var roomScreenAllowCameraAction
    
    @UserDefault(key: "roomScreenAllowMediaLibraryAction", defaultValue: BuildSettings.roomScreenAllowMediaLibraryAction, storage: defaults)
    var roomScreenAllowMediaLibraryAction
    
    @UserDefault(key: "roomScreenAllowStickerAction", defaultValue: BuildSettings.roomScreenAllowStickerAction, storage: defaults)
    var roomScreenAllowStickerAction
    
    @UserDefault(key: "roomScreenAllowFilesAction", defaultValue: BuildSettings.roomScreenAllowFilesAction, storage: defaults)
    var roomScreenAllowFilesAction
        
    @UserDefault(key: "roomScreenShowsURLPreviews", defaultValue: true, storage: defaults)
    var roomScreenShowsURLPreviews
    
    @UserDefault(key: "roomScreenEnableMessageBubbles", defaultValue: BuildSettings.isRoomScreenEnableMessageBubblesByDefault, storage: defaults)
    var roomScreenEnableMessageBubbles

    var roomTimelineStyleIdentifier: RoomTimelineStyleIdentifier {
        return self.roomScreenEnableMessageBubbles ? .bubble : .plain
    }

    /// A setting used to display the latest known display name and avatar in the timeline
    /// for both the sender and target, rather than the profile at the time of the event.
    ///
    /// Note: this is set up from Room perspective, which means that if a user updates their profile after
    /// leaving a Room, it will show up the latest profile used in the Room rather than the latest overall.
    @UserDefault(key: "roomScreenUseOnlyLatestUserAvatarAndName", defaultValue: BuildSettings.roomScreenUseOnlyLatestUserAvatarAndName, storage: defaults)
    var roomScreenUseOnlyLatestUserAvatarAndName
    
    // MARK: - Room Contextual Menu
    
    @UserDefault(key: "roomContextualMenuShowMoreOptionForMessages", defaultValue: BuildSettings.roomContextualMenuShowMoreOptionForMessages, storage: defaults)
    var roomContextualMenuShowMoreOptionForMessages
    
    @UserDefault(key: "roomContextualMenuShowMoreOptionForStates", defaultValue: BuildSettings.roomContextualMenuShowMoreOptionForStates, storage: defaults)
    var roomContextualMenuShowMoreOptionForStates
    
    @UserDefault(key: "roomContextualMenuShowReportContentOption", defaultValue: BuildSettings.roomContextualMenuShowReportContentOption, storage: defaults)
    var roomContextualMenuShowReportContentOption
    
    // MARK: - Room Info Screen
    
    @UserDefault(key: "roomInfoScreenShowIntegrations", defaultValue: BuildSettings.roomInfoScreenShowIntegrations, storage: defaults)
    var roomInfoScreenShowIntegrations
    
    // MARK: - Room Member Screen
    
    @UserDefault(key: "roomMemberScreenShowIgnore", defaultValue: BuildSettings.roomMemberScreenShowIgnore, storage: defaults)
    var roomMemberScreenShowIgnore
    
    // MARK: - Room Creation Screen
    
    @UserDefault(key: "roomCreationScreenAllowEncryptionConfiguration", defaultValue: BuildSettings.roomCreationScreenAllowEncryptionConfiguration, storage: defaults)
    var roomCreationScreenAllowEncryptionConfiguration
    
    @UserDefault(key: "roomCreationScreenRoomIsEncrypted", defaultValue: BuildSettings.roomCreationScreenRoomIsEncrypted, storage: defaults)
    var roomCreationScreenRoomIsEncrypted
    
    @UserDefault(key: "roomCreationScreenAllowRoomTypeConfiguration", defaultValue: BuildSettings.roomCreationScreenAllowRoomTypeConfiguration, storage: defaults)
    var roomCreationScreenAllowRoomTypeConfiguration
    
    @UserDefault(key: "roomCreationScreenRoomIsPublic", defaultValue: BuildSettings.roomCreationScreenRoomIsPublic, storage: defaults)
    var roomCreationScreenRoomIsPublic
    
    // MARK: Features
    
    @UserDefault(key: "allowInviteExernalUsers", defaultValue: BuildSettings.allowInviteExernalUsers, storage: defaults)
    var allowInviteExernalUsers
    
    /// When set to false the original image is sent and a 1080p preset is used for videos.
    /// If `BuildSettings.roomInputToolbarCompressionMode` has a value other than prompt, the build setting takes priority for images.
    @UserDefault(key: "showMediaCompressionPrompt", defaultValue: false, storage: defaults)
    var showMediaCompressionPrompt
    
    // MARK: - Main Tabs
    
    @UserDefault(key: "homeScreenShowFavouritesTab", defaultValue: BuildSettings.homeScreenShowFavouritesTab, storage: defaults)
    var homeScreenShowFavouritesTab
    
    @UserDefault(key: "homeScreenShowPeopleTab", defaultValue: BuildSettings.homeScreenShowPeopleTab, storage: defaults)
    var homeScreenShowPeopleTab
    
    @UserDefault(key: "homeScreenShowRoomsTab", defaultValue: BuildSettings.homeScreenShowRoomsTab, storage: defaults)
    var homeScreenShowRoomsTab
    
    // MARK: General Settings
    
    @UserDefault(key: "settingsScreenShowChangePassword", defaultValue: BuildSettings.settingsScreenShowChangePassword, storage: defaults)
    var settingsScreenShowChangePassword
    
    @UserDefault(key: "settingsScreenShowEnableStunServerFallback", defaultValue: BuildSettings.settingsScreenShowEnableStunServerFallback, storage: defaults)
    var settingsScreenShowEnableStunServerFallback
    
    @UserDefault(key: "settingsScreenShowNotificationDecodedContentOption", defaultValue: BuildSettings.settingsScreenShowNotificationDecodedContentOption, storage: defaults)
    var settingsScreenShowNotificationDecodedContentOption
    
    @UserDefault(key: "settingsScreenShowNsfwRoomsOption", defaultValue: BuildSettings.settingsScreenShowNsfwRoomsOption, storage: defaults)
    var settingsScreenShowNsfwRoomsOption
    
    @UserDefault(key: "settingsSecurityScreenShowSessions", defaultValue: BuildSettings.settingsSecurityScreenShowSessions, storage: defaults)
    var settingsSecurityScreenShowSessions
    
    @UserDefault(key: "settingsSecurityScreenShowSetupBackup", defaultValue: BuildSettings.settingsSecurityScreenShowSetupBackup, storage: defaults)
    var settingsSecurityScreenShowSetupBackup
    
    @UserDefault(key: "settingsSecurityScreenShowRestoreBackup", defaultValue: BuildSettings.settingsSecurityScreenShowRestoreBackup, storage: defaults)
    var settingsSecurityScreenShowRestoreBackup
    
    @UserDefault(key: "settingsSecurityScreenShowDeleteBackup", defaultValue: BuildSettings.settingsSecurityScreenShowDeleteBackup, storage: defaults)
    var settingsSecurityScreenShowDeleteBackup
    
    @UserDefault(key: "settingsSecurityScreenShowCryptographyInfo", defaultValue: BuildSettings.settingsSecurityScreenShowCryptographyInfo, storage: defaults)
    var settingsSecurityScreenShowCryptographyInfo
    
    @UserDefault(key: "settingsSecurityScreenShowCryptographyExport", defaultValue: BuildSettings.settingsSecurityScreenShowCryptographyExport, storage: defaults)
    var settingsSecurityScreenShowCryptographyExport
    
    @UserDefault(key: "settingsSecurityScreenShowAdvancedBlacklistUnverifiedDevices", defaultValue: BuildSettings.settingsSecurityScreenShowAdvancedUnverifiedDevices, storage: defaults)
    var settingsSecurityScreenShowAdvancedUnverifiedDevices
    
    // MARK: - Room Settings Screen
    
    @UserDefault(key: "roomSettingsScreenShowLowPriorityOption", defaultValue: BuildSettings.roomSettingsScreenShowLowPriorityOption, storage: defaults)
    var roomSettingsScreenShowLowPriorityOption
    
    @UserDefault(key: "roomSettingsScreenShowDirectChatOption", defaultValue: BuildSettings.roomSettingsScreenShowDirectChatOption, storage: defaults)
    var roomSettingsScreenShowDirectChatOption
    
    @UserDefault(key: "roomSettingsScreenAllowChangingAccessSettings", defaultValue: BuildSettings.roomSettingsScreenAllowChangingAccessSettings, storage: defaults)
    var roomSettingsScreenAllowChangingAccessSettings
    
    @UserDefault(key: "roomSettingsScreenAllowChangingHistorySettings", defaultValue: BuildSettings.roomSettingsScreenAllowChangingHistorySettings, storage: defaults)
    var roomSettingsScreenAllowChangingHistorySettings
    
    @UserDefault(key: "roomSettingsScreenShowAddressSettings", defaultValue: BuildSettings.roomSettingsScreenShowAddressSettings, storage: defaults)
    var roomSettingsScreenShowAddressSettings
    
    @UserDefault(key: "roomSettingsScreenShowAdvancedSettings", defaultValue: BuildSettings.roomSettingsScreenShowAdvancedSettings, storage: defaults)
    var roomSettingsScreenShowAdvancedSettings
    
    @UserDefault(key: "roomSettingsScreenAdvancedShowEncryptToVerifiedOption", defaultValue: BuildSettings.roomSettingsScreenAdvancedShowEncryptToVerifiedOption, storage: defaults)
    var roomSettingsScreenAdvancedShowEncryptToVerifiedOption
    
    // MARK: - Unified Search
    
    @UserDefault(key: "unifiedSearchScreenShowPublicDirectory", defaultValue: BuildSettings.unifiedSearchScreenShowPublicDirectory, storage: defaults)
    var unifiedSearchScreenShowPublicDirectory
    
    // MARK: - Secrets Recovery
    
    @UserDefault(key: "secretsRecoveryAllowReset", defaultValue: BuildSettings.secretsRecoveryAllowReset, storage: defaults)
    var secretsRecoveryAllowReset
    
    // MARK: - Beta
    
    @UserDefault(key: "hideSpaceBetaAnnounce", defaultValue: false, storage: defaults)
    var hideSpaceBetaAnnounce

    @UserDefault(key: "threadsNoticeDisplayed", defaultValue: false, storage: defaults)
    var threadsNoticeDisplayed

    // MARK: - Version check
    
    @UserDefault(key: "versionCheckNextDisplayDateTimeInterval", defaultValue: 0.0, storage: defaults)
    var versionCheckNextDisplayDateTimeInterval
    
    @UserDefault(key: "slideMenuRoomsCoachMessageHasBeenDisplayed", defaultValue: false, storage: defaults)
    var slideMenuRoomsCoachMessageHasBeenDisplayed
    
    // MARK: - Metrics
    
    /// Number of spaces previously tracked by the `AnalyticsSpaceTracker` instance.
    @UserDefault(key: "lastNumberOfTrackedSpaces", defaultValue: nil, storage: defaults)
    var lastNumberOfTrackedSpaces: Int?
    
    // MARK: - All Chats Onboarding
    
    @UserDefault(key: "allChatsOnboardingHasBeenDisplayed", defaultValue: false, storage: defaults)
    var allChatsOnboardingHasBeenDisplayed
    
}

// MARK: - RiotSettings notification constants
extension RiotSettings {
    public static let didUpdateLiveLocationSharingActivation = Notification.Name("RiotSettingsDidUpdateLiveLocationSharingActivation")
}
