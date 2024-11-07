//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

protocol AuthenticationQRLoginLoadingViewModelProtocol {
    var callback: ((AuthenticationQRLoginLoadingViewModelResult) -> Void)? { get set }
    var context: AuthenticationQRLoginLoadingViewModelType.Context { get }
}
