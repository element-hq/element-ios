//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

typealias InfoSheetViewModelType = StateStoreViewModel<InfoSheetViewState, InfoSheetViewAction>

class InfoSheetViewModel: InfoSheetViewModelType, InfoSheetViewModelProtocol {
    var completion: ((InfoSheetViewModelResult) -> Void)?

    init(title: String, description: String, action: InfoSheet.Action) {
        super.init(initialViewState: InfoSheetViewState(title: title, description: description, action: action))
    }

    // MARK: - Public

    override func process(viewAction: InfoSheetViewAction) {
        switch viewAction {
        case .actionTriggered:
            completion?(.actionTriggered)
        }
    }
}
