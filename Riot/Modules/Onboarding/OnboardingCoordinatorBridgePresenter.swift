// File created from FlowTemplate
// $ createRootCoordinator.sh Onboarding/SplashScreen Onboarding OnboardingSplashScreen
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

/// OnboardingCoordinatorBridgePresenter enables to start OnboardingCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// **WARNING**: This class breaks the Coordinator abstraction and it has been introduced for **Objective-C compatibility only** (mainly for integration in legacy view controllers). Each bridge should be removed
/// once the underlying Coordinator has been integrated by another Coordinator.
@objcMembers
final class OnboardingCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Constants
    
    private enum NavigationType {
        case present
        case push
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private var navigationType: NavigationType = .present
    private var coordinator: OnboardingCoordinator?
    
    // MARK: Public
    
    var completion: (() -> Void)?
    
    // MARK: - Public
    
    func present(from viewController: UIViewController, animated: Bool) {
        let onboardingCoordinator = makeOnboardingCoordinator()
        
        let presentable = onboardingCoordinator.toPresentable()
        presentable.modalPresentationStyle = .fullScreen
        presentable.modalTransitionStyle = .crossDissolve
        
        viewController.present(presentable, animated: animated, completion: nil)
        onboardingCoordinator.start()
        
        self.coordinator = onboardingCoordinator
        self.navigationType = .present
    }
    
    func push(from navigationController: UINavigationController, animated: Bool) {
                
        let navigationRouter = NavigationRouterStore.shared.navigationRouter(for: navigationController)
        
        let onboardingCoordinator = makeOnboardingCoordinator(navigationRouter: navigationRouter)

        onboardingCoordinator.start() // Will trigger the view controller push
        
        self.coordinator = onboardingCoordinator
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
    
    // MARK: - Private
    
    /// Makes an `OnboardingCoordinator` using the supplied navigation router, or creating one if needed.
    private func makeOnboardingCoordinator(navigationRouter: NavigationRouterType? = nil) -> OnboardingCoordinator {
        let onboardingCoordinatorParameters = OnboardingCoordinatorParameters(router: navigationRouter)
        
        let onboardingCoordinator = OnboardingCoordinator(parameters: onboardingCoordinatorParameters)
        onboardingCoordinator.completion = { [weak self] in
            self?.completion?()
        }
        return onboardingCoordinator
    }
}
