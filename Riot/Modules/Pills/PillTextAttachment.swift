// 
// Copyright 2022 New Vector Ltd
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

import UIKit
import MatrixSDK

/// Text attachment for pills display.
@objcMembers class PillTextAttachment: NSTextAttachment {
    var roomMember: MXRoomMember?
    var isCurrentUser: Bool = false
    var alpha: CGFloat = 1.0

    convenience init(withRoomMember roomMember: MXRoomMember, isCurrentUser: Bool) {
        self.init(data: nil, ofType: "im.vector.app.pills")
        self.roomMember = roomMember
        self.isCurrentUser = isCurrentUser
        let pillSize = PillAttachmentView.size(forRoomMember: roomMember)
        self.bounds = CGRect(origin: CGPoint(x: 0.0, y: -6.5), size: pillSize)
    }
}
