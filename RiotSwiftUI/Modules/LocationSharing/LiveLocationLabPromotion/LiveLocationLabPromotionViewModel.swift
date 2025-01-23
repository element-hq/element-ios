//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

typealias LiveLocationLabPromotionViewModelType = StateStoreViewModel<LiveLocationLabPromotionViewState, LiveLocationLabPromotionViewAction>

class LiveLocationLabPromotionViewModel: LiveLocationLabPromotionViewModelType, LiveLocationLabPromotionViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var completion: ((Bool) -> Void)?

    // MARK: - Setup

    init() {
        let bindings = LiveLocationLabPromotionBindings(enableLabFlag: false)
        super.init(initialViewState: LiveLocationLabPromotionViewState(bindings: bindings))
    }

    // MARK: - Public

    override func process(viewAction: LiveLocationLabPromotionViewAction) {
        switch viewAction {
        case .complete:
            completion?(state.bindings.enableLabFlag)
        }
    }
}
