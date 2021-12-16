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
