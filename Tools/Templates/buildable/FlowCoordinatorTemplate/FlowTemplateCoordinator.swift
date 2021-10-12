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

import UIKit

@objcMembers
final class FlowTemplateCoordinator: NSObject, FlowTemplateCoordinatorProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
        
    private let parameters: FlowTemplateCoordinatorParameters
    
    private var navigationRouter: NavigationRouterType {
        return self.parameters.navigationRouter
    }
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: FlowTemplateCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(parameters: FlowTemplateCoordinatorParameters) {
        self.parameters = parameters
    }    
    
    // MARK: - Public
    
    func start() {

        let rootCoordinator = self.createTemplateScreenCoordinator()
        
        rootCoordinator.start()

        self.add(childCoordinator: rootCoordinator)
        
        // Detect when view controller has been dismissed by gesture when presented modally (not in full screen).
        self.navigationRouter.toPresentable().presentationController?.delegate = self
        
        if self.navigationRouter.modules.isEmpty == false {
            self.navigationRouter.push(rootCoordinator, animated: true, popCompletion: { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
            })
        } else {
            self.navigationRouter.setRootModule(rootCoordinator) { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
            }
        }
      }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private

    private func createTemplateScreenCoordinator() -> TemplateScreenCoordinator {
        let coordinatorParameters = TemplateScreenCoordinatorParameters(session: self.parameters.session)
        let coordinator = TemplateScreenCoordinator(parameters: coordinatorParameters)
        coordinator.delegate = self
        return coordinator
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension FlowTemplateCoordinator: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.delegate?.flowTemplateCoordinatorDidDismissInteractively(self)
    }
}

// MARK: - TemplateScreenCoordinatorDelegate
extension FlowTemplateCoordinator: TemplateScreenCoordinatorDelegate {
    func templateScreenCoordinator(_ coordinator: TemplateScreenCoordinatorProtocol, didCompleteWithUserDisplayName userDisplayName: String?) {
        self.delegate?.flowTemplateCoordinatorDidComplete(self)
    }
    
    func templateScreenCoordinatorDidCancel(_ coordinator: TemplateScreenCoordinatorProtocol) {
        self.delegate?.flowTemplateCoordinatorDidComplete(self)
    }
}
