// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Navigation parameters to display a preview of a room that is unknown for the user.
/// This room can come from an email invitation link or a simple link to a room.
@objcMembers
class RoomPreviewNavigationParameters: RoomNavigationParameters {
    
    // MARK: - Properties

    /// The data for the room preview
    let previewData: RoomPreviewData
    
    // MARK: - Setup
    
    init(previewData: RoomPreviewData, presentationParameters: ScreenPresentationParameters) {
        self.previewData = previewData

        super.init(roomId: previewData.roomId,
                   eventId: previewData.eventId,
                   mxSession: previewData.mxSession,
                   threadParameters: nil,
                   presentationParameters: presentationParameters)
    }
}
