//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol UserSessionsOverviewViewModelProtocol {
    var completion: ((UserSessionsOverviewViewModelResult) -> Void)? { get set }

    var context: UserSessionsOverviewViewModelType.Context { get }
}
