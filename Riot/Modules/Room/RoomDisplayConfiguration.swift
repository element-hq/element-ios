// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objcMembers
class RoomDisplayConfiguration: NSObject {
    
    let callsEnabled: Bool
    
    let integrationsEnabled: Bool
    
    let jitsiWidgetRemoverEnabled: Bool

    let sendingPollsEnabled: Bool
    
    init(callsEnabled: Bool,
         integrationsEnabled: Bool,
         jitsiWidgetRemoverEnabled: Bool,
         sendingPollsEnabled: Bool) {
        self.callsEnabled = callsEnabled
        self.integrationsEnabled = integrationsEnabled
        self.jitsiWidgetRemoverEnabled = jitsiWidgetRemoverEnabled
        self.sendingPollsEnabled = sendingPollsEnabled
        super.init()
    }
    
    static let `default`: RoomDisplayConfiguration = RoomDisplayConfiguration(callsEnabled: true,
                                                                              integrationsEnabled: true,
                                                                              jitsiWidgetRemoverEnabled: true,
                                                                              sendingPollsEnabled: true)
    
    static let forThreads: RoomDisplayConfiguration = RoomDisplayConfiguration(callsEnabled: false,
                                                                               integrationsEnabled: false,
                                                                               jitsiWidgetRemoverEnabled: false,
                                                                               sendingPollsEnabled: false)
}
