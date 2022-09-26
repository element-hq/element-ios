// 
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import CommonKit

struct UserSessionsFlowCoordinatorParameters {
    let session: MXSession
    let router: NavigationRouterType?
}

final class UserSessionsFlowCoordinator: Coordinator, Presentable {
    private let parameters: UserSessionsFlowCoordinatorParameters
    private let navigationRouter: NavigationRouterType
    
    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
    init(parameters: UserSessionsFlowCoordinatorParameters) {
        self.parameters = parameters
        navigationRouter = parameters.router ?? NavigationRouter(navigationController: RiotNavigationController())
    }
    
    // MARK: - Private
    
    private func pushScreen(with coordinator: Coordinator & Presentable) {
        add(childCoordinator: coordinator)
        
        navigationRouter.push(coordinator, animated: true, popCompletion: { [weak self] in
            self?.remove(childCoordinator: coordinator)
        })
        
        coordinator.start()
    }
    
    private func createUserSessionsOverviewCoordinator() -> UserSessionsOverviewCoordinator {
        let parameters = UserSessionsOverviewCoordinatorParameters(session: parameters.session)
        
        let coordinator = UserSessionsOverviewCoordinator(parameters: parameters)
        coordinator.completion = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .openSessionOverview(session: session, isCurrentSession: isCurrentSession):
                self.openSessionOverview(session: session, isCurrentSession: isCurrentSession)
            }
        }
        return coordinator
    }
    
    private func openSessionDetails(session: UserSessionInfo) {
        let coordinator = createUserSessionDetailsCoordinator(session: session)
        pushScreen(with: coordinator)
    }
    
    private func createUserSessionDetailsCoordinator(session: UserSessionInfo) -> UserSessionDetailsCoordinator {
        let parameters = UserSessionDetailsCoordinatorParameters(userSessionInfo: session)
        return UserSessionDetailsCoordinator(parameters: parameters)
    }
    
    private func openSessionOverview(session: UserSessionInfo, isCurrentSession: Bool) {
        let coordinator = createUserSessionOverviewCoordinator(session: session, isCurrentSession: isCurrentSession)
        coordinator.completion = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .openSessionDetails(session: session):
                self.openSessionDetails(session: session)
            }
        }
        pushScreen(with: coordinator)
    }
    
    private func createUserSessionOverviewCoordinator(session: UserSessionInfo, isCurrentSession: Bool) -> UserSessionOverviewCoordinator {
        let parameters = UserSessionOverviewCoordinatorParameters(userSessionInfo: session, isCurrentSession: isCurrentSession)
        return UserSessionOverviewCoordinator(parameters: parameters)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[UserSessionsFlowCoordinator] did start.")
        
        let rootCoordinator = createUserSessionsOverviewCoordinator()
        rootCoordinator.start()
        
        add(childCoordinator: rootCoordinator)
        
        if navigationRouter.modules.isEmpty == false {
            navigationRouter.push(rootCoordinator, animated: true, popCompletion: { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
                self?.completion?()
            })
        } else {
            navigationRouter.setRootModule(rootCoordinator) { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
                self?.completion?()
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return navigationRouter.toPresentable()
    }
}
