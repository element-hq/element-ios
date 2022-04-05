// File created from FlowTemplate
// $ createRootCoordinator.sh Threads Threads ThreadList
/*
 Copyright 2021 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
