// 
// Copyright 2021 New Vector Ltd
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
