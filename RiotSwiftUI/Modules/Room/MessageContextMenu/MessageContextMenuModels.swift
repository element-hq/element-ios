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
import UIKit

// MARK: - Coordinator

enum MessageContextMenuCoordinatorAction {
    case cancel
    case done(MessageContextMenuActionType)
    case updateReaction(_ reaction: String, _ selected: Bool)
    case moreReactions
}

// MARK: View model

struct MessageReactionMenuItem: Identifiable {
    var id: String { emoji }
    
    let emoji: String
    let isSelected: Bool
}

@objc enum MessageContextMenuActionType: Int {
    case reply
    case replyInThread
    case edit
    case remove
    case copy
    case quote
    case forward
    case copyLink
    case share
    case viewSource
    case report
    case resend
    case viewInRoom
    case cancelSending
    case save
    case cancelDownload
    case viewDecryptedSource
    case redact
    case endPoll
    case encryptionInfo
    case more
}

struct MessageContextMenuItemAttributes: OptionSet {
    let rawValue: Int
    
    static let destructive = MessageContextMenuItemAttributes(rawValue: 1)
    static let disabled = MessageContextMenuItemAttributes(rawValue: 2)
}


@available(iOS 13.0, *)
struct MessageContextMenuItem: Identifiable, Equatable {
    let id = UUID().uuidString
    let title: String
    let type: MessageContextMenuActionType
    let image: UIImage?
    let attributes: MessageContextMenuItemAttributes
    let children: [MessageContextMenuItem]
    
    init(title: String, type: MessageContextMenuActionType, image: UIImage? = nil, attributes: MessageContextMenuItemAttributes = [], children: [MessageContextMenuItem] = []) {
        self.title = title
        self.type = type
        self.image = image
        self.attributes = attributes
        self.children = children
    }
}

enum MessageContextMenuViewModelResult {
    case cancel
    case done(MessageContextMenuActionType)
    case updateReaction(_ reaction: String, _ selected: Bool)
    case moreReactions
}

// MARK: View

@available(iOS 13.0, *)
struct MessageContextMenuViewState: BindableState {
    let menu: [MessageContextMenuItem]
    let previewImage: UIImage?
    let intialFrame: CGRect
    let reactions: [MessageReactionMenuItem]
}

@available(iOS 13.0, *)
enum MessageContextMenuViewAction {
    case cancel
    case menuItemPressed(MessageContextMenuItem)
    case reactionItemPressed(MessageReactionMenuItem)
    case moreReactionsItemPressed
}
