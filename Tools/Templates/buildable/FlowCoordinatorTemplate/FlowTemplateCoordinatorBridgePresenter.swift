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

@objc protocol FlowTemplateCoordinatorBridgePresenterDelegate {
    func flowTemplateCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: FlowTemplateCoordinatorBridgePresenter)
    func flowTemplateCoordinatorBridgePresenterDidDismissInteractively(_ coordinatorBridgePresenter: FlowTemplateCoordinatorBridgePresenter)
}

/// FlowTemplateCoordinatorBridgePresenter enables to start FlowTemplateCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// **WARNING**: This class breaks the Coordinator abstraction and it has been introduced for **Objective-C compatibility only** (mainly for integration in legacy view controllers). Each bridge should be removed once the underlying Coordinator has been integrated by another Coordinator.
@objcMembers
final class FlowTemplateCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Constants
    
    private enum NavigationType {
        case present
        case push
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var navigationType: NavigationType = .present
    private var coordinator: FlowTemplateCoordinator?
    
    // MARK: Public
    
    weak var delegate: FlowTemplateCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        super.init()
    }
    
    // MARK: - Public
    
    // NOTE: Default value feature is not compatible with Objective-C.
    // func present(from viewController: UIViewController, animated: Bool) {
    //     self.present(from: viewController, animated: animated)
    // }
    
    func present(from viewController: UIViewController, animated: Bool) {
        
        let flowTemplateCoordinatorParameters = FlowTemplateCoordinatorParameters(session: self.session)
        
        let flowTemplateCoordinator = FlowTemplateCoordinator(parameters: flowTemplateCoordinatorParameters)
        flowTemplateCoordinator.delegate = self
        let presentable = flowTemplateCoordinator.toPresentable()
        viewController.present(presentable, animated: animated, completion: nil)
        flowTemplateCoordinator.start()
        
        self.coordinator = flowTemplateCoordinator
        self.navigationType = .present
    }
    
    func push(from navigationController: UINavigationController, animated: Bool) {
                
        let navigationRouter = NavigationRouterStore.shared.navigationRouter(for: navigationController)
        
        let flowTemplateCoordinatorParameters = FlowTemplateCoordinatorParameters(session: self.session, navigationRouter: navigationRouter)
        
        let flowTemplateCoordinator = FlowTemplateCoordinator(parameters: flowTemplateCoordinatorParameters)
        flowTemplateCoordinator.delegate = self
        flowTemplateCoordinator.start() // Will trigger the view controller push
        
        self.coordinator = flowTemplateCoordinator        
        self.navigationType = .push
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let coordinator = self.coordinator else {
            return
        }

        switch navigationType {
        case .present:
            // Dismiss modal
            coordinator.toPresentable().dismiss(animated: animated) {
                self.coordinator = nil

                if let completion = completion {
                    completion()
                }
            }
        case .push:
            // Pop view controller from UINavigationController
            guard let navigationController = coordinator.toPresentable() as? UINavigationController else {
                return
            }
            navigationController.popViewController(animated: animated)
            self.coordinator = nil

            if let completion = completion {
                completion()
            }
        }
    }
}

// MARK: - FlowTemplateCoordinatorDelegate
extension FlowTemplateCoordinatorBridgePresenter: FlowTemplateCoordinatorDelegate {
    
    func flowTemplateCoordinatorDidComplete(_ coordinator: FlowTemplateCoordinatorProtocol) {
        self.delegate?.flowTemplateCoordinatorBridgePresenterDelegateDidComplete(self)
    }
    
    func flowTemplateCoordinatorDidDismissInteractively(_ coordinator: FlowTemplateCoordinatorProtocol) {
        self.delegate?.flowTemplateCoordinatorBridgePresenterDidDismissInteractively(self)
    }
}
