//
// Copyright 2020 Vector Creations Ltd
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

/// BuildSettings provides settings computed at build time.
/// In future, it may be automatically generated from xcconfig files
@objcMembers
final class BuildSettings: NSObject {
    // MARK: - Bundle Settings

    static var applicationGroupIdentifier: String {
        guard let applicationGroupIdentifier = Bundle.app.object(forInfoDictionaryKey: "applicationGroupIdentifier") as? String else {
            fatalError("applicationGroupIdentifier should be defined")
        }
        return applicationGroupIdentifier
    }
    
    static var baseBundleIdentifier: String {
        guard let baseBundleIdentifier = Bundle.app.object(forInfoDictionaryKey: "baseBundleIdentifier") as? String else {
            fatalError("baseBundleIdentifier should be defined")
        }
        return baseBundleIdentifier
    }
    
    static var keychainAccessGroup: String {
        guard let keychainAccessGroup = Bundle.app.object(forInfoDictionaryKey: "keychainAccessGroup") as? String else {
            fatalError("keychainAccessGroup should be defined")
        }
        return keychainAccessGroup
    }
    
    static var applicationURLScheme: String? {
        guard let urlTypes = Bundle.app.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [AnyObject],
              let urlTypeDictionary = urlTypes.first as? [String: AnyObject],
              let urlSchemes = urlTypeDictionary["CFBundleURLSchemes"] as? [AnyObject],
              let externalURLScheme = urlSchemes.first as? String else {
            return nil
        }
        
        return externalURLScheme
    }
    
    static var pushKitAppIdProd: String {
        baseBundleIdentifier + ".ios.voip.prod"
    }
    
    static var pushKitAppIdDev: String {
        baseBundleIdentifier + ".ios.voip.dev"
    }
    
    static var pusherAppIdProd: String {
        baseBundleIdentifier + ".ios.prod"
    }
    
    static var pusherAppIdDev: String {
        baseBundleIdentifier + ".ios.dev"
    }
    
    static var pushKitAppId: String {
        #if DEBUG
        return pushKitAppIdDev
        #else
        return pushKitAppIdProd
        #endif
    }
    
    static var pusherAppId: String {
        #if DEBUG
        return pusherAppIdDev
        #else
        return pusherAppIdProd
        #endif
    }
    
    // Element-Web instance for the app
    static let applicationWebAppUrlString = "https://app.element.io"
    
    // MARK: - Localization
    
    /// Whether to allow the app to use a right to left layout or force left to right for all languages
    static let disableRightToLeftLayout = true
    
    // MARK: - Server configuration
    
    // Default servers proposed on the authentication screen
    static let serverConfigDefaultHomeserverUrlString = "https://matrix.org"
    static let serverConfigDefaultIdentityServerUrlString = "https://vector.im"
    
    static let serverConfigSygnalAPIUrlString = "https://matrix.org/_matrix/push/v1/notify"
    
    // MARK: - Legal URLs
    
    // Note: Set empty strings to hide the related entry in application settings
    static let applicationCopyrightUrlString = "https://element.io/copyright"
    static let applicationPrivacyPolicyUrlString = "https://element.io/privacy"
    static let applicationTermsConditionsUrlString = "https://element.io/terms-of-service"
    static let applicationHelpUrlString =
        "https://element.io/help"
    
    // MARK: - Permalinks

    // Hosts/Paths for URLs that will considered as valid permalinks. Those permalinks are opened within the app.
    static let permalinkSupportedHosts: [String: [String]] = [
        "app.element.io": [],
        "staging.element.io": [],
        "develop.element.io": [],
        "mobile.element.io": [""],
        // Historical ones
        "riot.im": ["/app", "/staging", "/develop"],
        "www.riot.im": ["/app", "/staging", "/develop"],
        "vector.im": ["/app", "/staging", "/develop"],
        "www.vector.im": ["/app", "/staging", "/develop"],
        // Official Matrix ones
        "matrix.to": ["/"],
        "www.matrix.to": ["/"]
        // Client Permalinks (for use with `BuildSettings.clientPermalinkBaseUrl`)
//        "example.com": ["/"],
//        "www.example.com": ["/"],
    ]
    
    // For use in clients that use a custom base url for permalinks rather than matrix.to.
    // This baseURL is used to generate permalinks within the app (E.g. timeline message permalinks).
    // Optional String that when set is used as permalink base, when nil matrix.to format is used.
    // Example value would be "https://www.example.com", note there is no trailing '/'.
    static let clientPermalinkBaseUrl: String? = nil
    
    // MARK: - VoIP

    static var allowVoIPUsage: Bool {
        #if canImport(JitsiMeetSDK)
        return true
        #else
        return false
        #endif
    }

    static let stunServerFallbackUrlString: String? = "stun:turn.matrix.org"
    
    // MARK: -  Public rooms Directory

    // List of homeservers for the public rooms directory
    static let publicRoomsDirectoryServers = [
        "matrix.org",
        "gitter.im"
    ]
    
    // MARK: -  Rooms Screen

    static let roomsAllowToJoinPublicRooms = true
    
    // MARK: - Analytics
    
    /// A type that represents how to set up the analytics module in the app.
    ///
    /// **Note:** Analytics are disabled by default for forks.
    /// If you are maintaining a fork, set custom configurations.
    struct AnalyticsConfiguration {
        /// Whether or not analytics should be enabled.
        let isEnabled: Bool
        /// The host to use for PostHog analytics.
        let host: String
        /// The public key for submitting analytics.
        let apiKey: String
        /// The URL to open with more information about analytics terms.
        let termsURL: URL
    }
    
    #if DEBUG
    /// The configuration to use for analytics during development. Set `isEnabled` to false to disable analytics in debug builds.
    static let analyticsConfiguration = AnalyticsConfiguration(isEnabled: BuildSettings.baseBundleIdentifier.starts(with: "im.vector.app"),
                                                               host: "https://posthog.element.dev",
                                                               apiKey: "phc_VtA1L35nw3aeAtHIx1ayrGdzGkss7k1xINeXcoIQzXN",
                                                               termsURL: URL(string: "https://element.io/cookie-policy")!)
    #else
    /// The configuration to use for analytics. Set `isEnabled` to false to disable analytics.
    static let analyticsConfiguration = AnalyticsConfiguration(isEnabled: BuildSettings.baseBundleIdentifier.starts(with: "im.vector.app"),
                                                               host: "https://posthog.hss.element.io",
                                                               apiKey: "phc_Jzsm6DTm6V2705zeU5dcNvQDlonOR68XvX2sh1sEOHO",
                                                               termsURL: URL(string: "https://element.io/cookie-policy")!)
    #endif
    
    // MARK: - Bug report

    static let bugReportEndpointUrlString = "https://riot.im/bugreports"
    // Use the name allocated by the bug report server
    static let bugReportApplicationId = "riot-ios"
    static let bugReportUISIId = "element-auto-uisi"
    
    // MARK: - Integrations

    static let integrationsUiUrlString = "https://scalar.vector.im/"
    static let integrationsRestApiUrlString = "https://scalar.vector.im/api"
    // Widgets in those paths require a scalar token
    static let integrationsScalarWidgetsPaths = [
        "https://scalar.vector.im/_matrix/integrations/v1",
        "https://scalar.vector.im/api",
        "https://scalar-staging.vector.im/_matrix/integrations/v1",
        "https://scalar-staging.vector.im/api",
        "https://scalar-staging.riot.im/scalar/api"
    ]
    // Jitsi server used outside integrations to create conference calls from the call button in the timeline.
    // Setting this to nil effectively disables Jitsi conference calls (given that there is no wellknown override).
    // Note: this will not remove the conference call button, use roomScreenAllowVoIPForNonDirectRoom setting.
    static let jitsiServerUrl: URL? = URL(string: "https://jitsi.riot.im")

    // MARK: - Features
    
    /// Setting to force protection by pin code
    static let forcePinProtection = false
    
    /// Max allowed time to continue using the app without prompting PIN
    static let pinCodeGraceTimeInSeconds: TimeInterval = 0
    
    /// Force non-jailbroken app usage
    static let forceNonJailbrokenUsage = true
    
    static let allowSendingStickers = true
    
    static let allowLocalContactsAccess = true
    
    static let allowInviteExernalUsers = true
    
    // MARK: - Side Menu

    static let enableSideMenu = true && !newAppLayoutEnabled
    static let sideMenuShowInviteFriends = true

    /// Whether to read the `io.element.functional_members` state event and exclude any service members when computing a room's name and avatar.
    static let supportFunctionalMembers = true
    
    // MARK: - Feature Specifics
    
    /// Not allowed pin codes. User won't be able to select one of the pin in the list.
    static let notAllowedPINs: [String] = []
    
    /// Maximum number of allowed pin failures when unlocking, before force logging out the user. Defaults to `3`
    static let maxAllowedNumberOfPinFailures = 3
    
    /// Maximum number of allowed biometrics failures when unlocking, before fallbacking the user to the pin if set or logging out the user. Defaults to `5`
    static let maxAllowedNumberOfBiometricsFailures = 5
    
    /// Indicates should the app log out the user when number of PIN failures reaches `maxAllowedNumberOfPinFailures`. Defaults to `false`
    static let logOutUserWhenPINFailuresExceeded = false
    
    /// Indicates should the app log out the user when number of biometrics failures reaches `maxAllowedNumberOfBiometricsFailures`. Defaults to `false`
    static let logOutUserWhenBiometricsFailuresExceeded = false
    
    static let showNotificationsV2 = true
    
    // MARK: - Main Tabs
    
    static let homeScreenShowFavouritesTab = true
    static let homeScreenShowPeopleTab = true
    static let homeScreenShowRoomsTab = true

    // MARK: - General Settings Screen
    
    static let settingsScreenShowUserFirstName = false
    static let settingsScreenShowUserSurname = false
    static let settingsScreenAllowAddingEmailThreepids = true
    static let settingsScreenAllowAddingPhoneThreepids = true
    static let settingsScreenShowThreepidExplanatory = true
    static let settingsScreenShowDiscoverySettings = true
    static let settingsScreenAllowIdentityServerConfig = true
    static let settingsScreenShowConfirmMediaSize = true
    static let settingsScreenShowAdvancedSettings = true
    static let settingsScreenShowLabSettings = true
    static let settingsScreenAllowChangingRageshakeSettings = true
    static let settingsScreenAllowChangingCrashUsageDataSettings = true
    static let settingsScreenAllowBugReportingManually = true
    static let settingsScreenAllowDeactivatingAccount = true
    static let settingsScreenShowChangePassword = true
    static let settingsScreenShowEnableStunServerFallback = true
    static let settingsScreenShowNotificationDecodedContentOption = true
    static let settingsScreenShowNsfwRoomsOption = true
    static let settingsSecurityScreenShowSessions = true
    static let settingsSecurityScreenShowSetupBackup = true
    static let settingsSecurityScreenShowRestoreBackup = true
    static let settingsSecurityScreenShowDeleteBackup = true
    static let settingsSecurityScreenShowCryptographyInfo = true
    static let settingsSecurityScreenShowCryptographyExport = true
    static let settingsSecurityScreenShowAdvancedUnverifiedDevices = true
    /// A setting to enable the presence configuration settings section.
    static let settingsScreenPresenceAllowConfiguration = false

    // MARK: - Timeline settings

    static let roomInputToolbarCompressionMode: MediaCompressionMode = .prompt
    
    enum MediaCompressionMode {
        case prompt, small, medium, large, none
    }
    
    // MARK: - Room Creation Screen
    
    static let roomCreationScreenAllowEncryptionConfiguration = true
    static let roomCreationScreenRoomIsEncrypted = true
    static let roomCreationScreenAllowRoomTypeConfiguration = true
    static let roomCreationScreenRoomIsPublic = false
    
    // MARK: - Room Screen
    
    static let roomScreenAllowVoIPForDirectRoom = true
    static let roomScreenAllowVoIPForNonDirectRoom = true
    static let roomScreenAllowCameraAction = true
    static let roomScreenAllowMediaLibraryAction = true
    static let roomScreenAllowStickerAction = true
    static let roomScreenAllowFilesAction = true
    
    // Timeline style
    static let roomScreenAllowTimelineStyleConfiguration = true
    static let roomScreenTimelineDefaultStyleIdentifier: RoomTimelineStyleIdentifier = .plain
    static var isRoomScreenEnableMessageBubblesByDefault: Bool {
        roomScreenTimelineDefaultStyleIdentifier == .bubble
    }

    static let roomScreenUseOnlyLatestUserAvatarAndName = false

    /// Allow split view detail view stacking
    static let allowSplitViewDetailsScreenStacking = true
    
    // MARK: - Room Contextual Menu

    static let roomContextualMenuShowMoreOptionForMessages = true
    static let roomContextualMenuShowMoreOptionForStates = true
    static let roomContextualMenuShowReportContentOption = true

    // MARK: - Room Info Screen
    
    static let roomInfoScreenShowIntegrations = true

    // MARK: - Room Settings Screen
    
    static let roomSettingsScreenShowLowPriorityOption = true
    static let roomSettingsScreenShowDirectChatOption = true
    static let roomSettingsScreenAllowChangingAccessSettings = true
    static let roomSettingsScreenAllowChangingHistorySettings = true
    static let roomSettingsScreenShowAddressSettings = true
    static let roomSettingsScreenShowAdvancedSettings = true
    static let roomSettingsScreenAdvancedShowEncryptToVerifiedOption = true

    // MARK: - Room Member Screen
    
    static let roomMemberScreenShowIgnore = true

    // MARK: - Message

    static let messageDetailsAllowShare = true
    static let messageDetailsAllowPermalink = true
    static let messageDetailsAllowViewSource = true
    static let messageDetailsAllowSave = true
    static let messageDetailsAllowCopyMedia = true
    static let messageDetailsAllowPasteMedia = true
    
    // MARK: - Notifications

    static let decryptNotificationsByDefault = true
    
    // MARK: - HTTP

    /// Additional HTTP headers will be sent by all requests. Not recommended to use request-specific headers, like `Authorization`.
    /// Empty dictionary by default.
    static let httpAdditionalHeaders: [String: String] = [:]
    
    // MARK: - Authentication Screen

    static let authScreenShowRegister = true
    static let authScreenShowPhoneNumber = true
    static let authScreenShowForgotPassword = true
    static let authScreenShowCustomServerOptions = true
    static let authScreenShowSocialLoginSection = true
    
    // MARK: - Authentication Options

    static let authEnableRefreshTokens = false
    
    // MARK: - Onboarding

    static let onboardingShowAccountPersonalization = true
    static let onboardingEnableNewAuthenticationFlow = true
    
    // MARK: - Unified Search

    static let unifiedSearchScreenShowPublicDirectory = true
    
    // MARK: - Secrets Recovery

    static let secretsRecoveryAllowReset = true
    
    // MARK: - UISI Autoreporting

    static let cryptoUISIAutoReportingEnabled = false
    
    // MARK: - Polls
    
    static let pollsEnabled = true
    
    // MARK: - Location Sharing
    
    /// Overwritten by the home server's .well-known configuration (if any exists)
    static let defaultTileServerMapStyleURL = URL(string: "https://api.maptiler.com/maps/streets/style.json?key=fU3vlMsMn4Jb6dnEIFsx")!
    
    static let locationSharingEnabled = true

    // MARK: - MXKAppSettings

    static let enableBotCreation = false
    static let maxAllowedMediaCacheSize = 1_073_741_824
    static let presenceColorForOfflineUser = 15_020_851
    static let presenceColorForOnlineUser = 3_401_011
    static let presenceColorForUnavailableUser = 15_066_368
    static let showAllEventsInRoomHistory = false
    static let showLeftMembersInRoomMemberList = false
    static let showRedactionsInRoomHistory = true
    static let showUnsupportedEventsInRoomHistory = false
    static let sortRoomMembersUsingLastSeenTime = true
    static let syncLocalContacts = false
    
    // MARK: - New App Layout

    static let newAppLayoutEnabled = true
    
    // MARK: - Device manager
    
    static let deviceManagerEnabled = false
}
