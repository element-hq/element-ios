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
                linkAction: .edit(link: link),
                bindings: .init(
                    text: "",
                    linkUrl: link
                )
            )
        case .createWithText:
            initialViewState = .init(linkAction: .createWithText, bindings: simpleBindings)
        case .create:
            initialViewState = .init(linkAction: .create, bindings: simpleBindings)
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
            }
        }
    }
}
