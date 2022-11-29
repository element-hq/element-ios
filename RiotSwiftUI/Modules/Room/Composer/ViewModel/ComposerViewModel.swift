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
    
    // MARK: - Public
    
    override func process(viewAction: ComposerViewAction) {
        switch viewAction {
        case .cancel:
            callback?(.cancel)
        case let .contentDidChange(isEmpty):
            callback?(.contentDidChange(isEmpty: isEmpty))
        }
    }
    
    func dismissKeyboard() {
        state.bindings.focused = false
    }
    
    func showKeyboard() {
        state.bindings.focused = true
    }
}
