// 
// Copyright 2024 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

struct ToastViewState {
    enum Style {
        case loading
        case success
        case failure
        case custom(icon: UIImage?)
    }
    
    let style: Style
    let label: String
}
