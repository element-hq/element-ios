// File created from FlowTemplate
// $ createRootCoordinator.sh SetPinCode SetPin EnterPinCode
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
final class SetPinCoordinator: SetPinCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    private let session: MXSession?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: SetPinCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession?) {
        self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        self.session = session
    }    
    
    // MARK: - Public methods
    
    func start() {

        let rootCoordinator = self.createEnterPinCodeCoordinator()

        rootCoordinator.start()

        self.add(childCoordinator: rootCoordinator)

        self.navigationRouter.setRootModule(rootCoordinator)
    }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private methods

    private func createEnterPinCodeCoordinator() -> EnterPinCodeCoordinator {
        let coordinator = EnterPinCodeCoordinator(session: self.session)
        coordinator.delegate = self
        return coordinator
    }
    
    private func storePin(_ pin: String) {
        // TODO: Implement this
    }
}

// MARK: - EnterPinCodeCoordinatorDelegate
extension SetPinCoordinator: EnterPinCodeCoordinatorDelegate {
    func enterPinCodeCoordinator(_ coordinator: EnterPinCodeCoordinatorType, didCompleteWithPin pin: String) {
        storePin(pin)
        self.delegate?.setPinCoordinatorDidComplete(self)
    }
    
    func enterPinCodeCoordinatorDidCancel(_ coordinator: EnterPinCodeCoordinatorType) {
        self.delegate?.setPinCoordinatorDidComplete(self)
    }
}
