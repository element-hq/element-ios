// File created from FlowTemplate
// $ createRootCoordinator.sh Modal ServiceTermsModal ServiceTermsModalLoadTermsScreen
/*
 Copyright 2019 New Vector Ltd
 
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
final class ServiceTermsModalCoordinator: ServiceTermsModalCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    private let session: MXSession
    private let serviceTerms: MXServiceTerms

    private var policies: [MXLoginPolicyData]?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ServiceTermsModalCoordinatorDelegate?
    
    // MARK: - Setup
    init(session: MXSession, baseUrl: String, serviceType: MXServiceType) {
        self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        self.session = session
        self.serviceTerms = MXServiceTerms(baseUrl: baseUrl, serviceType: serviceType)
    }
    
    // MARK: - Public methods
    
    func start() {

        let rootCoordinator = self.createServiceTermsModalLoadTermsScreenCoordinator()

        rootCoordinator.start()

        self.add(childCoordinator: rootCoordinator)

        self.navigationRouter.setRootModule(rootCoordinator)
      }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private methods

    private func createServiceTermsModalLoadTermsScreenCoordinator() -> ServiceTermsModalLoadTermsScreenCoordinator {
        let coordinator = ServiceTermsModalLoadTermsScreenCoordinator(serviceTerms: self.serviceTerms)
        coordinator.delegate = self
        return coordinator
    }
}

// MARK: - ServiceTermsModalLoadTermsScreenCoordinatorDelegate
extension ServiceTermsModalCoordinator: ServiceTermsModalLoadTermsScreenCoordinatorDelegate {
    func serviceTermsModalLoadTermsScreenCoordinator(_ coordinator: ServiceTermsModalLoadTermsScreenCoordinatorType, didCompleteWithTerms terms: MXLoginTerms?) {
        guard let terms = terms else {
            // TODO: but what?
            return
        }

        self.policies = terms.policiesData(forLanguage: Bundle.mxk_language(), defaultLanguage: Bundle.mxk_fallbackLanguage())
    }

    func serviceTermsModalLoadTermsScreenCoordinatorDidCancel(_ coordinator: ServiceTermsModalLoadTermsScreenCoordinatorType) {
        self.delegate?.serviceTermsModalCoordinatorDidAccept(self)
    }
}
