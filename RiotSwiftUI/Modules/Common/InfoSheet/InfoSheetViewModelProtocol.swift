//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol InfoSheetViewModelProtocol {
    var completion: ((InfoSheetViewModelResult) -> Void)? { get set }
    var context: InfoSheetViewModelType.Context { get }
}
