/*
Copyright 2021-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
