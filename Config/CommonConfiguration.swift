// 
// Copyright 2024 New Vector Ltd.
// Copyright 2020 Vector Creations Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixSDK

#if !os(OSX)
import DeviceKit
#endif

/// CommonConfiguration is the central point to setup settings for MatrixSDK, MatrixKit and common configurations for all targets.
class CommonConfiguration: NSObject, Configurable {
    
    // MARK: - Global settings
    
    func setupSettings() {
        setupMatrixKitSettings()
        setupMatrixSDKSettings()
    }
    
    private func setupMatrixKitSettings() {
        guard let settings = MXKAppSettings.standard() else {
            return
        }
        
        // Disable CallKit
        settings.isCallKitEnabled = false
        
        // Enable lazy loading
        settings.syncWithLazyLoadOfRoomMembers = true
        
        // Customize the default notification content
        settings.notificationBodyLocalizationKey = "Notification"
        
        settings.messageDetailsAllowSharing = BuildSettings.messageDetailsAllowShare
        settings.messageDetailsAllowSaving = BuildSettings.messageDetailsAllowSave
        settings.messageDetailsAllowCopyingMedia = BuildSettings.messageDetailsAllowCopyMedia
        settings.messageDetailsAllowPastingMedia = BuildSettings.messageDetailsAllowPasteMedia
        
        // Enable link detection if url preview are enabled
        settings.enableBubbleComponentLinkDetection = true
        
        MXKContactManager.shared().allowLocalContactsAccess = BuildSettings.allowLocalContactsAccess
    }
    
    private func setupMatrixSDKSettings() {
        let sdkOptions = MXSDKOptions.sharedInstance()
        
        sdkOptions.applicationGroupIdentifier = BuildSettings.applicationGroupIdentifier
        
        // Define the media cache version
        sdkOptions.mediaCacheAppVersion = 0
        
        // Enable e2e encryption for newly created MXSession
        sdkOptions.enableCryptoWhenStartingMXSession = true
        
        // Disable identicon use
        sdkOptions.disableIdenticonUseForUserAvatar = true
        
        // Set up user agent
        if let userAgent = makeASCIIUserAgent() {
            sdkOptions.httpAdditionalHeaders = ["User-Agent": userAgent]
        }

        // Pass httpAdditionalHeaders to the SDK
        sdkOptions.httpAdditionalHeaders = (sdkOptions.httpAdditionalHeaders ?? [:]).merging(BuildSettings.httpAdditionalHeaders, uniquingKeysWith: { _, value in value })
        
        // Disable key backup on common
        sdkOptions.enableKeyBackupWhenStartingMXCrypto = false

        // Pass threading option to the SDK
        sdkOptions.enableThreads = RiotSettings.shared.enableThreads
        
        sdkOptions.clientPermalinkBaseUrl = BuildSettings.clientPermalinkBaseUrl
        
        sdkOptions.authEnableRefreshTokens = BuildSettings.authEnableRefreshTokens
        // Configure key provider delegate
        MXKeyProvider.sharedInstance().delegate = EncryptionKeyManager.shared

        sdkOptions.enableNewClientInformationFeature = RiotSettings.shared.enableClientInformationFeature
        
        sdkOptions.cryptoMigrationDelegate = self
    }
    
    private func makeASCIIUserAgent() -> String? {
        guard var userAgent = makeUserAgent() else {
            return nil
        }
        if !userAgent.canBeConverted(to: .ascii) {
            let mutableUserAgent = NSMutableString(string: userAgent)
            if CFStringTransform(mutableUserAgent, nil, "Any-Latin; Latin-ASCII; [:^ASCII:] Remove" as CFString, false) {
                userAgent = mutableUserAgent as String
            }
        }
        return userAgent
    }
    
    private func makeUserAgent() -> String? {
        let appInfo = AppInfo.current
        let clientName = appInfo.displayName
        let clientVersion = appInfo.appVersion?.bundleShortVersion ?? "unknown"

    #if os(iOS)
        return String(
            format: "%@/%@ (%@; iOS %@; Scale/%0.2f)",
                clientName,
                clientVersion,
                Device.current.safeDescription,
                UIDevice.current.systemVersion,
                UIScreen.main.scale)
    #elseif os(tvOS)
        return String(
            format: "%@/%@ (%@; tvOS %@; Scale/%0.2f)",
                clientName,
                clientVersion,
                Device.current.safeDescription,
                UIDevice.current.systemVersion,
                UIScreen.main.scale)
    #elseif os(watchOS)
        return String(
            format: "%@/%@ (%@; watchOS %@; Scale/%0.2f)",
                clientName,
                clientVersion,
                Device.current.safeDescription,
                WKInterfaceDevice.current.systemVersion,
                WKInterfaceDevice.currentDevice.screenScale)
    #elseif os(OSX)
        return String(
            format: "%@/%@ (Mac; Mac OS X %@)",
                clientName,
                clientVersion,
                NSProcessInfo.processInfo.operatingSystemVersionString)
    #else
        return nil
    #endif
    }
    
    
    // MARK: - Per matrix session settings
    
    func setupSettings(for matrixSession: MXSession) {
        setupCallsSettings(for: matrixSession)
    }
    
    private func setupCallsSettings(for matrixSession: MXSession) {
        guard let callManager = matrixSession.callManager else {
            // This means nothing happens if the project does not embed a VoIP stack
            return
        }
        
        // Let's call invite be valid for 1 minute
        callManager.inviteLifetime = 60000
        
        if RiotSettings.shared.allowStunServerFallback, let stunServerFallback = BuildSettings.stunServerFallbackUrlString {
            callManager.fallbackSTUNServer = stunServerFallback
        }
    }    
}

extension CommonConfiguration: MXCryptoV2MigrationDelegate {
    var needsVerificationUpgrade: Bool {
        get {
            RiotSettings.shared.showVerificationUpgradeAlert
        }
        set {
            RiotSettings.shared.showVerificationUpgradeAlert = newValue
        }
    }
}
