/*
 Copyright 2020 New Vector Ltd
 
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

import UIKit

@objcMembers
final class FlowTemplateCoordinator: FlowTemplateCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    private let session: MXSession
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: FlowTemplateCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        self.session = session
    }    
    
    // MARK: - Public methods
    
    func start() {

        let rootCoordinator = self.createTemplateScreenCoordinator()

        rootCoordinator.start()

        self.add(childCoordinator: rootCoordinator)

        self.navigationRouter.setRootModule(rootCoordinator)
      }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private methods

    private func createTemplateScreenCoordinator() -> TemplateScreenCoordinator {
        let coordinator = TemplateScreenCoordinator(session: self.session)
        coordinator.delegate = self
        return coordinator
    }
}

// MARK: - TemplateScreenCoordinatorDelegate
extension FlowTemplateCoordinator: TemplateScreenCoordinatorDelegate {
    func templateScreenCoordinator(_ coordinator: TemplateScreenCoordinatorType, didCompleteWithUserDisplayName userDisplayName: String?) {
        self.delegate?.flowTemplateCoordinatorDidComplete(self)
    }
    
    func templateScreenCoordinatorDidCancel(_ coordinator: TemplateScreenCoordinatorType) {
        self.delegate?.flowTemplateCoordinatorDidComplete(self)
    }
}
