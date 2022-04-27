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

@available(iOS 15.0, *)
/// Provider for mention Pills attachment view.
@objc class PillAttachmentViewProvider: NSTextAttachmentViewProvider {
    override func loadView() {
        super.loadView()

        guard let textAttachment = self.textAttachment as? PillTextAttachment else {
            MXLog.debug("[PillAttachmentViewProvider]: attachment is not of expected class")
            return
        }

        guard let roomMember = textAttachment.roomMember else {
            MXLog.debug("[PillAttachmentViewProvider]: attachment misses room member data")
            return
        }

        view = PillSnapshoter.snapshotView(forRoomMember: roomMember)
        view?.alpha = textAttachment.alpha
    }
}
