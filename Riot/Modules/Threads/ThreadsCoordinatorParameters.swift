// File created from FlowTemplate
// $ createRootCoordinator.sh Threads Threads ThreadList
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// ThreadsCoordinator input parameters
struct ThreadsCoordinatorParameters {
    
    /// The Matrix session
    let session: MXSession
    
    /// Room identifier
    let roomId: String

    /// Thread identifier. Specified thread will be opened if provided, the thread list otherwise
    let threadId: String?
                
    /// The navigation router that manage physical navigation
    let navigationRouter: NavigationRouterType
    
    let userIndicatorPresenter: UserIndicatorTypePresenterProtocol
    
    init(session: MXSession,
         roomId: String,
         threadId: String?,
         userIndicatorPresenter: UserIndicatorTypePresenterProtocol,
         navigationRouter: NavigationRouterType? = nil) {
        self.session = session
        self.roomId = roomId
        self.threadId = threadId
        self.userIndicatorPresenter = userIndicatorPresenter
        self.navigationRouter = navigationRouter ?? NavigationRouter(navigationController: RiotNavigationController())
    }
}
