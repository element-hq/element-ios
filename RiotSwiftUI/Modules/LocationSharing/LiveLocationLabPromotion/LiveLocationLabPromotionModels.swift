//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

// MARK: View

struct LiveLocationLabPromotionViewState: BindableState {
    var bindings: LiveLocationLabPromotionBindings
}

struct LiveLocationLabPromotionBindings {
    var enableLabFlag: Bool
}

enum LiveLocationLabPromotionViewAction {
    case complete
}
