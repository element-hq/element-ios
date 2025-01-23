//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

// MARK: View model

enum InfoSheetViewModelResult {
    case actionTriggered
}

// MARK: View

struct InfoSheetViewState: BindableState {
    let title: String
    let description: String
    let action: InfoSheet.Action
}

enum InfoSheetViewAction {
    case actionTriggered
}
