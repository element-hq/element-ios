/*
Copyright 2022-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
