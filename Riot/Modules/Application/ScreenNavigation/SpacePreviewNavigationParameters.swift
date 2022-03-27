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

/// Navigation parameters to display a preview of a space that is unknown for the user.
@objcMembers
class SpacePreviewNavigationParameters: SpaceNavigationParameters {
    
    // MARK: - Properties

    /// The data for the room preview
    let publicRoom: MXPublicRoom
    
    /// The ID of the sender of the invite
    let senderId: String?
    
    // MARK: - Setup
    
    init(publicRoom: MXPublicRoom,
         mxSession: MXSession,
         presentationParameters: ScreenPresentationParameters) {
        self.publicRoom = publicRoom
        self.senderId = nil
        
        super.init(roomId: publicRoom.roomId,
                   mxSession: mxSession,
                   presentationParameters: presentationParameters)
    }
    
    init(publicRoom: MXPublicRoom,
         mxSession: MXSession,
         senderId: String?,
         presentationParameters: ScreenPresentationParameters) {
        self.publicRoom = publicRoom
        self.senderId = senderId
        
        super.init(roomId: publicRoom.roomId,
                   mxSession: mxSession,
                   presentationParameters: presentationParameters)
    }
}
