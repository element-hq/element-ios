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
