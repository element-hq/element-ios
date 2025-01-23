//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
