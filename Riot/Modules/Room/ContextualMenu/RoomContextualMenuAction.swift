/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
