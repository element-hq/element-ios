// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

typealias ComposerViewModelType = StateStoreViewModel<ComposerViewState, ComposerViewAction>

final class ComposerViewModel: ComposerViewModelType, ComposerViewModelProtocol {
    // MARK: - Properties

    // MARK: Private
    
    // MARK: Public
    
    var callback: ((ComposerViewModelResult) -> Void)?
    
    var sendMode: ComposerSendMode {
        get {
            state.sendMode
        }
        set {
            state.sendMode = newValue
        }
    }

    var textFormattingEnabled: Bool {
        get {
            state.textFormattingEnabled
        }
        set {
            state.textFormattingEnabled = newValue
        }
    }
    
    var eventSenderDisplayName: String? {
        get {
            state.eventSenderDisplayName
        }
        set {
            state.eventSenderDisplayName = newValue
        }
    }
    
    var placeholder: String? {
        get {
            state.placeholder
        }
        set {
            state.placeholder = newValue
        }
    }
    
    var isLandscapePhone: Bool {
        get {
            state.isLandscapePhone
        }
        set {
            state.isLandscapePhone = newValue
        }
    }
    
    var isFocused: Bool {
        state.bindings.focused
    }
    
    var selectionToRestore: NSRange?
    
    // MARK: - Public
    
    override func process(viewAction: ComposerViewAction) {
        switch viewAction {
        case .cancel:
            callback?(.cancel)
        case let .contentDidChange(isEmpty):
            callback?(.contentDidChange(isEmpty: isEmpty))
        case let .linkTapped(linkAction):
            callback?(.linkTapped(LinkAction: linkAction))
        case let .storeSelection(selection):
            selectionToRestore = selection
        case let .suggestion(pattern: pattern):
            callback?(.suggestion(pattern: pattern))
        }
    }
    
    func dismissKeyboard() {
        state.bindings.focused = false
    }
    
    func showKeyboard() {
        state.bindings.focused = true
    }
}
