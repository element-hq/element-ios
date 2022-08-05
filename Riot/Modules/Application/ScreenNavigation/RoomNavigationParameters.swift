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
class ThreadParameters: NSObject {
    
    /// If not nil, the thread will be opened on this room
    let threadId: String
    
    /// If true, related room screen will be stacked in the navigation stack
    let stackRoomScreen: Bool
    
    init(threadId: String,
         stackRoomScreen: Bool) {
        self.threadId = threadId
        self.stackRoomScreen = stackRoomScreen
        super.init()
    }
    
}

/// Navigation parameters to display a room with a provided identifier in a specific matrix session.
@objcMembers
class RoomNavigationParameters: NSObject {
    
    // MARK: - Properties

    /// The room identifier. `nil` on new DM
    let roomId: String?
    
    /// The user identifier to create a new DM
    let userId: String?
    
    /// If not nil, the room will be opened on this event.
    let eventId: String?
    
    /// The Matrix session in which the room should be available.
    let mxSession: MXSession
    
    /// Navigation parameters for a thread
    let threadParameters: ThreadParameters?
    
    /// Screen presentation parameters.
    let presentationParameters: ScreenPresentationParameters
    
    /// If `true`, the room settings screen will be initially displayed. Default `false`
    let showSettingsInitially: Bool
    
    /// ID of the sender of the notification. Default `nil`
    let senderId: String?
    
    /// If `true`, the invited room is automatically joined.
    let autoJoinInvitedRoom: Bool
    
    // MARK: - Setup
    
    init(roomId: String,
         eventId: String?,
         mxSession: MXSession,
         threadParameters: ThreadParameters?,
         presentationParameters: ScreenPresentationParameters,
         autoJoinInvitedRoom: Bool
    ) {
        self.roomId = roomId
        self.userId = nil
        self.eventId = eventId
        self.mxSession = mxSession
        self.threadParameters = threadParameters
        self.presentationParameters = presentationParameters
        self.showSettingsInitially = false
        self.senderId = nil
        self.autoJoinInvitedRoom = autoJoinInvitedRoom
        
        super.init()
    }
    
    init(roomId: String,
         eventId: String?,
         mxSession: MXSession,
         threadParameters: ThreadParameters?,
         presentationParameters: ScreenPresentationParameters
    ) {
        self.roomId = roomId
        self.userId = nil
        self.eventId = eventId
        self.mxSession = mxSession
        self.threadParameters = threadParameters
        self.presentationParameters = presentationParameters
        self.showSettingsInitially = false
        self.senderId = nil
        self.autoJoinInvitedRoom = false

        super.init()
    }
    
    init(roomId: String,
         eventId: String?,
         mxSession: MXSession,
         senderId: String?,
         threadParameters: ThreadParameters?,
         presentationParameters: ScreenPresentationParameters) {
        self.roomId = roomId
        self.userId = nil
        self.eventId = eventId
        self.mxSession = mxSession
        self.threadParameters = threadParameters
        self.presentationParameters = presentationParameters
        self.showSettingsInitially = false
        self.senderId = senderId
        self.autoJoinInvitedRoom = false
        
        super.init()
    }
    
    init(roomId: String,
         eventId: String?,
         mxSession: MXSession,
         presentationParameters: ScreenPresentationParameters,
         showSettingsInitially: Bool) {
        self.roomId = roomId
        self.userId = nil
        self.eventId = eventId
        self.mxSession = mxSession
        self.presentationParameters = presentationParameters
        self.showSettingsInitially = showSettingsInitially
        self.threadParameters = nil
        self.senderId = nil
        self.autoJoinInvitedRoom = false

        super.init()
    }
    
    init(userId: String,
         mxSession: MXSession,
         presentationParameters: ScreenPresentationParameters) {
        self.roomId = nil
        self.userId = userId
        self.eventId = nil
        self.mxSession = mxSession
        self.threadParameters = nil
        self.presentationParameters = presentationParameters
        self.showSettingsInitially = false
        self.senderId = nil
        self.autoJoinInvitedRoom = false
        
        super.init()
    }
}
