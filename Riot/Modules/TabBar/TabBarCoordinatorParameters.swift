// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

/// TabBarCoordinator input parameters
class TabBarCoordinatorParameters {
    
    let userSessionsService: UserSessionsService
    let appNavigator: AppNavigatorProtocol
    
    init(userSessionsService: UserSessionsService, appNavigator: AppNavigatorProtocol) {
        self.userSessionsService = userSessionsService
        self.appNavigator = appNavigator
    }
}
