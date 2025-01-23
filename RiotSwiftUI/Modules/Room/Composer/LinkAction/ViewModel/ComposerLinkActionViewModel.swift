// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import WysiwygComposer

typealias ComposerLinkActionViewModelType = StateStoreViewModel<ComposerLinkActionViewState, ComposerLinkActionViewAction>

final class ComposerLinkActionViewModel: ComposerLinkActionViewModelType, ComposerLinkActionViewModelProtocol {
    // MARK: - Properties
    
    // MARK: Private
    
    // MARK: Public
    
    var callback: ((ComposerLinkActionViewModelResult) -> Void)?
    
    // MARK: - Public
    
    init(from linkAction: LinkAction) {
        let initialViewState: ComposerLinkActionViewState
        let simpleBindings = ComposerLinkActionBindings(text: "", linkUrl: "")
        switch linkAction {
        case let .edit(link):
            initialViewState = .init(
                linkAction: .edit(url: link),
                bindings: .init(
                    text: "",
                    linkUrl: link
                )
            )
        case .createWithText:
            initialViewState = .init(linkAction: .createWithText, bindings: simpleBindings)
        case .create:
            initialViewState = .init(linkAction: .create, bindings: simpleBindings)
        case .disabled:
            // Note: Unreachable
            initialViewState = .init(linkAction: .disabled, bindings: simpleBindings)
        }
        
        super.init(initialViewState: initialViewState)
    }
    
    override func process(viewAction: ComposerLinkActionViewAction) {
        switch viewAction {
        case .cancel:
            callback?(.cancel)
        case .remove:
            callback?(.performOperation(.removeLinks))
        case .save:
            switch state.linkAction {
            case .createWithText:
                callback?(
                    .performOperation(
                        .createLink(
                            urlString: state.bindings.linkUrl,
                            text: state.bindings.text
                        )
                    )
                )
            case .create, .edit:
                callback?(
                    .performOperation(
                        .setLink(urlString: state.bindings.linkUrl)
                    )
                )
            case .disabled:
                break
            }
        }
    }
}
