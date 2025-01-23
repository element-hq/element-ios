//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol LiveLocationLabPromotionViewModelProtocol {
    /// Closure called when screen completes. Indicates true if the lab flag has been enabled.
    var completion: ((Bool) -> Void)? { get set }
    
    var context: LiveLocationLabPromotionViewModelType.Context { get }
}
