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
import WysiwygComposer

enum ComposerLinkActionViewAction: Equatable {
    case cancel
    case save
    case remove
}

enum ComposerLinkActionViewModelResult: Equatable {
    case cancel
    case performOperation(_ linkOperation: WysiwygLinkOperation)
}

// MARK: View

struct ComposerLinkActionViewState: BindableState {
    let linkAction: LinkAction
    
    var bindings: ComposerLinkActionBindings
}

extension ComposerLinkActionViewState {
    var title: String {
        switch linkAction {
        case .createWithText, .create: return VectorL10n.wysiwygComposerLinkActionCreateTitle
        case .edit: return VectorL10n.wysiwygComposerLinkActionEditTitle
        case .disabled: return ""
        }
    }
    
    var shouldDisplayTextField: Bool {
        switch linkAction {
        case .createWithText: return true
        default: return false
        }
    }
    
    var shouldDisplayRemoveButton: Bool {
        switch linkAction {
        case .edit: return true
        default: return false
        }
    }
    
    var isSaveButtonDisabled: Bool {
        guard !bindings.linkUrl.isEmpty else { return true }
        switch linkAction {
        case .createWithText: return bindings.text.isEmpty
        case .create: return false
        case .edit: return !bindings.hasEditedUrl
        case .disabled: return false
        }
    }
}

struct ComposerLinkActionBindings {
    var text: String
    
    private let initialLinkUrl: String
    fileprivate var hasEditedUrl = false
    var linkUrl: String {
        didSet {
            if !hasEditedUrl && linkUrl != initialLinkUrl {
                hasEditedUrl = true
            }
        }
    }
    
    init(text: String, linkUrl: String) {
        self.text = text
        self.linkUrl = linkUrl
        self.initialLinkUrl = linkUrl
    }
}
