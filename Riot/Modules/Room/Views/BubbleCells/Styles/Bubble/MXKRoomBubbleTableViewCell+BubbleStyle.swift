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

extension MXKRoomBubbleTableViewCell {
    
    // Enables to get existing bubble background view
    // This used while there is no dedicated cell classes for bubble style
    var messageBubbleBackgroundView: RoomMessageBubbleBackgroundView? {
        
        let foundView = self.contentView.subviews.first { view in
            return view is RoomMessageBubbleBackgroundView
        }
        return foundView as? RoomMessageBubbleBackgroundView
    }
}
