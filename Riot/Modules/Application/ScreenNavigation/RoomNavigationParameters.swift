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

    /// The room identifier
    let roomId: String
    
    /// If not nil, the room will be opened on this event.
    let eventId: String?
    
    /// The Matrix session in which the room should be available.
    let mxSession: MXSession
    
    /// Navigation parameters for a thread
    let threadParameters: ThreadParameters?
    
    /// Screen presentation parameters.
    let presentationParameters: ScreenPresentationParameters
    
    // MARK: - Setup
    
    init(roomId: String,
         eventId: String?,
         mxSession: MXSession,
         threadParameters: ThreadParameters?,
         presentationParameters: ScreenPresentationParameters) {
        self.roomId = roomId
        self.eventId = eventId
        self.mxSession = mxSession
        self.threadParameters = threadParameters
        self.presentationParameters = presentationParameters
        
        super.init()
    }
}
