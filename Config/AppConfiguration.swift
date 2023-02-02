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

import Combine
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
    
    private var pushRulesUpdater: PushRulesUpdater?
    
    override func setupSettings(for matrixSession: MXSession) {
        super.setupSettings(for: matrixSession)
        setupWidgetReadReceipts(for: matrixSession)
        setupPushRuleSync(for: matrixSession)
    }
}

private extension AppConfiguration {
    func setupWidgetReadReceipts(for matrixSession: MXSession) {
        var acknowledgableEventTypes = matrixSession.acknowledgableEventTypes ?? []
        acknowledgableEventTypes.append(kWidgetMatrixEventTypeString)
        acknowledgableEventTypes.append(kWidgetModularEventTypeString)

        matrixSession.acknowledgableEventTypes = acknowledgableEventTypes
    }
    
    func setupPushRuleSync(for matrixSession: MXSession) {
        let firstSyncEnded = NotificationCenter.default.publisher(for: .mxSessionDidSync)
            .first()
            .eraseOutput()

        let rulesDidChange = NotificationCenter.default.publisher(for: NSNotification.Name(rawValue: kMXNotificationCenterDidUpdateRules)).eraseOutput()
        
        let rules = Publishers.Merge(rulesDidChange, firstSyncEnded)
            .compactMap { _ ->  [MXPushRule]? in
                guard let center = matrixSession.notificationCenter else {
                    return nil
                }
                
                return center.flatRules as? [MXPushRule]
            }
            .eraseToAnyPublisher()
        
        let applicationDidBecomeActive = NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification).eraseOutput()
        let needsRulesCheck = Publishers.Merge(firstSyncEnded, applicationDidBecomeActive).eraseOutput()
        
        pushRulesUpdater = .init(notificationSettingsService: MXNotificationSettingsService(session: matrixSession),
                                 rules: rules,
                                 needsCheck: needsRulesCheck)
    }
}
