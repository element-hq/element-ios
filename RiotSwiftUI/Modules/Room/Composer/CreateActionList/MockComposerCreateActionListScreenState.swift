//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

enum MockComposerCreateActionListScreenState: MockScreenState, CaseIterable {
    case partialList
    case fullList
    
    var screenType: Any.Type {
        ComposerCreateActionList.self
    }
    
    var screenView: ([Any], AnyView) {
        let actions: [ComposerCreateAction]
        switch self {
        case .partialList:
            actions = [.photoLibrary, .polls]
        case .fullList:
            actions = ComposerCreateAction.allCases
        }
        let viewModel = ComposerCreateActionListViewModel(
            initialViewState: ComposerCreateActionListViewState(
                actions: actions,
                wysiwygEnabled: true,
                isScrollingEnabled: false,
                bindings: ComposerCreateActionListBindings(
                    textFormattingEnabled: true
                )
            )
        )
        
        return (
            [viewModel],
            AnyView(ComposerCreateActionList(viewModel: viewModel.context))
        )
    }
}
