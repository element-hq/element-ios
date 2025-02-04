//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum MockComposerLinkActionScreenState: MockScreenState, CaseIterable {
    case edit
    case createWithText
    case create
    
    var screenType: Any.Type {
        ComposerLinkAction.self
    }
    
    var screenView: ([Any], AnyView) {
        let viewModel: ComposerLinkActionViewModel
        switch self {
        case .createWithText:
            viewModel = .init(from: .createWithText)
        case .create:
            viewModel = .init(from: .create)
        case .edit:
            viewModel = .init(from: .edit(url: "https://element.io"))
        }
        return (
            [viewModel],
            AnyView(ComposerLinkAction(viewModel: viewModel.context))
        )
    }
}
