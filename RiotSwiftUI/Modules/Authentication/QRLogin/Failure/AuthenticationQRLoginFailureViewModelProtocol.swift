//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

protocol AuthenticationQRLoginFailureViewModelProtocol {
    var callback: ((AuthenticationQRLoginFailureViewModelResult) -> Void)? { get set }
    var context: AuthenticationQRLoginFailureViewModelType.Context { get }
}
