//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

typealias TemplateSimpleScreenViewModelType = StateStoreViewModel<TemplateSimpleScreenViewState, TemplateSimpleScreenViewAction>

class TemplateSimpleScreenViewModel: TemplateSimpleScreenViewModelType, TemplateSimpleScreenViewModelProtocol {
    var completion: ((TemplateSimpleScreenViewModelResult) -> Void)?

    init(promptType: TemplateSimpleScreenPromptType, initialCount: Int = 0) {
        super.init(initialViewState: TemplateSimpleScreenViewState(promptType: promptType, count: 0))
    }

    // MARK: - Public

    override func process(viewAction: TemplateSimpleScreenViewAction) {
        switch viewAction {
        case .accept:
            completion?(.accept)
        case .cancel:
            completion?(.cancel)
        case .incrementCount:
            state.count += 1
        case .decrementCount:
            state.count -= 1
        }
    }
}
