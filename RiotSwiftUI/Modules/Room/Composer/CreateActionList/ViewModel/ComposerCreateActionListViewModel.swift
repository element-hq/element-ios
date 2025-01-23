//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

typealias ComposerCreateActionListViewModelType = StateStoreViewModel<ComposerCreateActionListViewState, ComposerCreateActionListViewAction>

class ComposerCreateActionListViewModel: ComposerCreateActionListViewModelType, ComposerCreateActionListViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var callback: ((ComposerCreateActionListViewModelResult) -> Void)?

    // MARK: - Setup

    // MARK: - Public

    override func process(viewAction: ComposerCreateActionListViewAction) {
        switch viewAction {
        case .selectAction(let action):
            callback?(.done(action))
        case .toggleTextFormatting(let enabled):
            callback?(.toggleTextFormatting(enabled))
        }
    }
}
