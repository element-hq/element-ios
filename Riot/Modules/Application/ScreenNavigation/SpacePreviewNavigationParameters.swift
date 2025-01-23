// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
