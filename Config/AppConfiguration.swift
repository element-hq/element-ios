// 
// Copyright 2024 New Vector Ltd.
// Copyright 2020 Vector Creations Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// AppConfiguration is CommonConfiguration plus configurations dedicated to the app
class AppConfiguration: CommonConfiguration {
    
    // MARK: - Global settings
    
    override func setupSettings() {
        super.setupSettings()
        setupAppSettings()
    }
    
    private func setupAppSettings() {
        // Enable CallKit for app
        MXKAppSettings.standard()?.isCallKitEnabled = true
        
        // Get additional events (modular widget, voice broadcast...)
        MXKAppSettings.standard()?.addSupportedEventTypes([kWidgetMatrixEventTypeString,
                                                           kWidgetModularEventTypeString,
                                                           VoiceBroadcastSettings.voiceBroadcastInfoContentKeyType])
        
        // Hide undecryptable messages that were sent while the user was not in the room
        MXKAppSettings.standard()?.hidePreJoinedUndecryptableEvents = true
        
        // Enable long press on event in bubble cells
        MXKRoomBubbleTableViewCell.disableLongPressGesture(onEvent: false)
        
        // Each room member will be considered as a potential contact.
        MXKContactManager.shared().contactManagerMXRoomSource = MXKContactManagerMXRoomSource.all
        
        // Use UIKit BackgroundTask for handling background tasks in the SDK
        MXSDKOptions.sharedInstance().backgroundModeHandler = MXUIKitBackgroundModeHandler()
        
        // Enable key backup on app
        MXSDKOptions.sharedInstance().enableKeyBackupWhenStartingMXCrypto = true
    }
    
    
    // MARK: - Per matrix session settings
    
    override func setupSettings(for matrixSession: MXSession) {
        super.setupSettings(for: matrixSession)
        setupWidgetReadReceipts(for: matrixSession)
    }
  
    private func setupWidgetReadReceipts(for matrixSession: MXSession) {
        var acknowledgableEventTypes = matrixSession.acknowledgableEventTypes ?? []
        acknowledgableEventTypes.append(kWidgetMatrixEventTypeString)
        acknowledgableEventTypes.append(kWidgetModularEventTypeString)

        matrixSession.acknowledgableEventTypes = acknowledgableEventTypes
    }
    
}
