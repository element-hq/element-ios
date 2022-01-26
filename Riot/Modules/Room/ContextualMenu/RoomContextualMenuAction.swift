/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

@objc enum RoomContextualMenuAction: Int {
    case copy
    case reply
    case replyInThread
    case edit
    case more
    case resend
    case delete
    
    // MARK: - Properties
    
    var title: String {
        let title: String
        
        switch self {
        case .copy:
            title = VectorL10n.roomEventActionCopy
        case .reply:
            title = VectorL10n.roomEventActionReply
        case .replyInThread:
            title = VectorL10n.roomEventActionReplyInThread
        case .edit:
            title = VectorL10n.roomEventActionEdit
        case .more:
            title = VectorL10n.roomEventActionMore
        case .resend:
            title = VectorL10n.retry
        case .delete:
            title = VectorL10n.roomEventActionDelete
        }
        
        return title
    }
    
    var image: UIImage? {
        let image: UIImage?
        
        switch self {
        case .copy:
            image = Asset.Images.roomContextMenuCopy.image
        case .reply:
            image = Asset.Images.roomContextMenuReply.image
        case .replyInThread:
            image = Asset.Images.roomContextMenuThread.image
        case .edit:
            image = Asset.Images.roomContextMenuEdit.image
        case .more:
            image = Asset.Images.roomContextMenuMore.image
        case .resend:
            image = Asset.Images.roomContextMenuRetry.image
        case .delete:
            image = Asset.Images.roomContextMenuDelete.image
        default:
            image = nil
        }
        
        return image
    }
}
