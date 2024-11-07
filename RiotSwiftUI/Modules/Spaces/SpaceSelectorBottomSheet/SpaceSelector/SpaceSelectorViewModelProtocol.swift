//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

protocol SpaceSelectorViewModelProtocol {
    var completion: ((SpaceSelectorViewModelResult) -> Void)? { get set }
    static func makeViewModel(service: SpaceSelectorServiceProtocol, showCancel: Bool) -> SpaceSelectorViewModelProtocol
    var context: SpaceSelectorViewModelType.Context { get }
}
