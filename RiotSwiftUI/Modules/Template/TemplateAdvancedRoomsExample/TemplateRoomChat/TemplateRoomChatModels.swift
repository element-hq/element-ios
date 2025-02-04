//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

// MARK: - Coordinator

/// An image sent as a message.
struct TemplateRoomChatMessageImageContent: Equatable {
    var image: UIImage
}

/// The text content of a message sent by a user.
struct TemplateRoomChatMessageTextContent: Equatable {
    var body: String
}

/// The type of message a long with it's content.
enum TemplateRoomChatMessageContent: Equatable {
    case text(TemplateRoomChatMessageTextContent)
    case image(TemplateRoomChatMessageImageContent)
}

enum TemplateRoomChatBubbleItemContent: Equatable {
    case message(TemplateRoomChatMessageContent)
}

/// One of the items grouped within a bubble(could be message types like text, image or video, or could be other items like url previews).
struct TemplateRoomChatBubbleItem: Identifiable, Equatable {
    let id: String
    var timestamp: Date
    var content: TemplateRoomChatBubbleItemContent
}

/// A user who is a member of the room.
struct TemplateRoomChatMember: Identifiable, Equatable, Avatarable {
    let id: String
    let avatarUrl: String?
    let displayName: String?
    
    var mxContentUri: String? {
        avatarUrl
    }
    
    var matrixItemId: String {
        id
    }
}

/// Represents a grouped bubble in the View(For example multiple message of different time sent close together).
struct TemplateRoomChatBubble: Identifiable, Equatable {
    let id: String
    let sender: TemplateRoomChatMember
    var items: [TemplateRoomChatBubbleItem]
}

/// A chat message send to the timeline within a room.
struct TemplateRoomChatMessage: Identifiable {
    let id: String
    let content: TemplateRoomChatMessageContent
    let sender: TemplateRoomChatMember
    let timestamp: Date
}

// MARK: - View model

enum TemplateRoomChatRoomInitializationStatus {
    case notInitialized
    case initialized
    case failedToInitialize
}

/// Actions sent by the `ViewModel` to the `Coordinator`
enum TemplateRoomChatViewModelAction {
    case done
}

// MARK: - View

/// Actions send from the `View` to the `ViewModel`.
enum TemplateRoomChatViewAction {
    case sendMessage
    case done
}

/// State managed by the `ViewModel` delivered to the `View`.
struct TemplateRoomChatViewState: BindableState {
    var roomInitializationStatus: TemplateRoomChatRoomInitializationStatus
    let roomName: String?
    var bubbles: [TemplateRoomChatBubble]
    var bindings: TemplateRoomChatViewModelBindings
    
    var sendButtonEnabled: Bool {
        !bindings.messageInput.isEmpty
    }
}

/// State bound directly to SwiftUI elements.
struct TemplateRoomChatViewModelBindings {
    var messageInput: String
}
