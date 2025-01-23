//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI
import WysiwygComposer

enum MockComposerScreenState: MockScreenState, CaseIterable {
    case send
    case edit
    case reply
    
    var screenType: Any.Type {
        Composer.self
    }
    
    var screenView: ([Any], AnyView) {
        let viewModel: ComposerViewModel
        let completionSuggestionViewModel = MockCompletionSuggestionViewModel(initialViewState: CompletionSuggestionViewState(items: []))
        let bindings = ComposerBindings(focused: false)
        
        switch self {
        case .send: viewModel = ComposerViewModel(initialViewState: ComposerViewState(textFormattingEnabled: true,
                                                                                      isLandscapePhone: false,
                                                                                      bindings: bindings))
        case .edit: viewModel = ComposerViewModel(initialViewState: ComposerViewState(sendMode: .edit,
                                                                                      textFormattingEnabled: true,
                                                                                      isLandscapePhone: false,
                                                                                      bindings: bindings))
        case .reply: viewModel = ComposerViewModel(initialViewState: ComposerViewState(eventSenderDisplayName: "TestUser",
                                                                                       sendMode: .reply,
                                                                                       textFormattingEnabled: true,
                                                                                       isLandscapePhone: false,
                                                                                       bindings: bindings))
        }
        
        let wysiwygviewModel = WysiwygComposerViewModel(minHeight: 20, maxCompressedHeight: 360)
        
        viewModel.callback = { [weak viewModel, weak wysiwygviewModel] result in
            guard let viewModel = viewModel else { return }
            switch result {
            case .cancel:
                if viewModel.sendMode == .edit {
                    wysiwygviewModel?.setHtmlContent("")
                }
                viewModel.sendMode = .send
            default: break
            }
        }
        
        return (
            [viewModel, wysiwygviewModel],
            AnyView(VStack {
                Spacer()
                Composer(viewModel: viewModel.context,
                         wysiwygViewModel: wysiwygviewModel,
                         completionSuggestionSharedContext: completionSuggestionViewModel.context,
                         resizeAnimationDuration: 0.1,
                         sendMessageAction: { _ in },
                         showSendMediaActions: { })
            }.frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity,
                alignment: .topLeading
            ))
        )
    }
}

private final class MockCompletionSuggestionViewModel: CompletionSuggestionViewModelType { }
