/*
 Copyright 2022 New Vector Ltd
 
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
import MatrixSDK
import UIKit

/// UserSessionsFlowCoordinatorBridgePresenter enables to start UserSessionsFlowCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// **WARNING**: This class breaks the Coordinator abstraction and it has been introduced for **Objective-C compatibility only** (mainly for integration in legacy view controllers).
/// Each bridge should be removed once the underlying Coordinator has been integrated by another Coordinator.
@objcMembers
final class UserSessionsFlowCoordinatorBridgePresenter: NSObject {
    private let mxSession: MXSession
    private var coordinator: UserSessionsFlowCoordinator?
        
    var completion: (() -> Void)?
    
    init(mxSession: MXSession) {
        self.mxSession = mxSession
        super.init()
    }
    
    // MARK: - Public

    func push(from navigationController: UINavigationController, animated: Bool) {
        startUserSessionsFlow(mxSession: mxSession, navigationController: navigationController)
    }
    
    // MARK: - Private
    
    private func startUserSessionsFlow(mxSession: MXSession, navigationController: UINavigationController) {
        let navigationRouter = NavigationRouterStore.shared.navigationRouter(for: navigationController)
        
        let parameters = UserSessionsFlowCoordinatorParameters(session: mxSession, router: navigationRouter)
        let coordinator = UserSessionsFlowCoordinator(parameters: parameters)
        
        coordinator.completion = { [weak self] in
            guard let self = self else {
                return
            }
            
            self.completion?()
            self.coordinator = nil
        }
        
        coordinator.start()
        
        self.coordinator = coordinator
    }
}
