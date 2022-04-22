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
import MatrixSDK

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
        
        // Pass httpAdditionalHeaders to the SDK
        sdkOptions.httpAdditionalHeaders = BuildSettings.httpAdditionalHeaders
        
        // Disable key backup on common
        sdkOptions.enableKeyBackupWhenStartingMXCrypto = false

        // Pass threading option to the SDK
        sdkOptions.enableThreads = RiotSettings.shared.enableThreads
        
        sdkOptions.clientPermalinkBaseUrl = BuildSettings.clientPermalinkBaseUrl
        
        sdkOptions.authEnableRefreshTokens = BuildSettings.authEnableRefreshTokens
        // Configure key provider delegate
        MXKeyProvider.sharedInstance().delegate = EncryptionKeyManager.shared
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
    
    
    // MARK: - Per loaded matrix session settings
    
    func setupSettingsWhenLoaded(for matrixSession: MXSession) {
        // Do not warn for unknown devices. We have cross-signing now
        matrixSession.crypto.warnOnUnknowDevices = false
    }
    
}
