// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct ComposerViewState: BindableState {
    var eventSenderDisplayName: String?
    var sendMode: ComposerSendMode = .send
    var textFormattingEnabled: Bool
    var isLandscapePhone: Bool
    var placeholder: String?
    
    var bindings: ComposerBindings
}

extension ComposerViewState {
    var shouldDisplayContext: Bool {
        sendMode == .edit || sendMode == .reply
    }
    
    var contextDescription: String? {
        switch sendMode {
        case .reply:
            guard let eventSenderDisplayName = eventSenderDisplayName else { return nil }
            return VectorL10n.roomMessageReplyingTo(eventSenderDisplayName)
        case .edit: return VectorL10n.roomMessageEditing
        default: return nil
        }
    }
    
    var contextImageName: String? {
        switch sendMode {
        case .edit: return Asset.Images.inputEditIcon.name
        case .reply: return Asset.Images.inputReplyIcon.name
        default: return nil
        }
    }
    
    var isMinimiseForced: Bool {
        isLandscapePhone || !textFormattingEnabled
    }
}

struct ComposerBindings {
    var focused: Bool
}
