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

import UIKit

/// OnboardingCoordinator input parameters
struct OnboardingCoordinatorParameters {
                
    /// The navigation router that manage physical navigation
    let router: NavigationRouterType
    
    init(router: NavigationRouterType? = nil) {
        self.router = router ?? NavigationRouter(navigationController: RiotNavigationController())
    }
}

@objcMembers
final class OnboardingCoordinator: NSObject, Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
        
    private let parameters: OnboardingCoordinatorParameters
    
//    private var currentPresentable: Presentable?
    
    private var navigationRouter: NavigationRouterType {
        parameters.router
    }
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((OnboardingSplashScreenViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: OnboardingCoordinatorParameters) {
        self.parameters = parameters
    }
    
    // MARK: - Public
    
    func start() {
        let rootCoordinator: Coordinator & Presentable
        
        if #available(iOS 14.0, *) {
            rootCoordinator = self.createOnboardingSplashScreenCoordinator()
        } else {
            #warning("Show the regular auth view here")
            return
        }
        
        rootCoordinator.start()

        add(childCoordinator: rootCoordinator)
        
//        currentPresentable = rootCoordinator.toPresentable()
//        parameters.router.setRootModule(rootCoordinator.toPresentable())

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
//        #warning("Forced unwrap")
//        return currentPresentable!.toPresentable()
        navigationRouter.toPresentable()
    }
    
    // MARK: - Private

    @available(iOS 14.0, *)
    private func createOnboardingSplashScreenCoordinator() -> OnboardingSplashScreenCoordinator {
        let coordinatorParameters = OnboardingSplashScreenCoordinatorParameters()
        let coordinator = OnboardingSplashScreenCoordinator(parameters: coordinatorParameters)
        coordinator.completion = { [weak self] result in
            guard let self = self else { return }
            self.completion?(result)
        }
        return coordinator
    }
}
