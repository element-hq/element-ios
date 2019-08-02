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
    private var acceptedPolicies: [MXLoginPolicyData]
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ServiceTermsModalCoordinatorDelegate?
    
    // MARK: - Setup
    init(session: MXSession, baseUrl: String, serviceType: MXServiceType) {
        self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        self.session = session
        self.serviceTerms = MXServiceTerms(baseUrl: baseUrl, serviceType: serviceType)
        self.acceptedPolicies = []
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

    private func createServiceTermsModalShowTermScreenCoordinator(policy: MXLoginPolicyData, progress: Progress) -> ServiceTermsModalShowTermScreenCoordinator {
        let coordinator = ServiceTermsModalShowTermScreenCoordinator(policy: policy, progress: progress)
        coordinator.delegate = self
        return coordinator
    }

    private func presentNextPolicy(nextPolicy: MXLoginPolicyData, progress: Progress) {

        let coordinator = self.createServiceTermsModalShowTermScreenCoordinator(policy: nextPolicy, progress: progress)

        self.add(childCoordinator: coordinator)

        self.navigationRouter.push(coordinator, animated: true) {
            self.remove(childCoordinator: coordinator)
        }

        coordinator.start()
    }

    private func processNextPolicy() {
        guard let policies = self.policies else {
            print("[ServiceTermsModalCoordinator] processNextPolicy: No terms loaded. Leave")
            self.delegate?.serviceTermsModalCoordinatorDidCancel(self)
            return
        }

        if self.acceptedPolicies.count == policies.count {
            // TODO: Send the info the servers
            self.delegate?.serviceTermsModalCoordinatorDidCancel(self)
        } else {
            let nextPolicyIndex = self.acceptedPolicies.count

            let nextPolicy = policies[nextPolicyIndex]
            let progress = Progress(totalUnitCount: Int64(policies.count))
            progress.completedUnitCount = Int64(self.acceptedPolicies.count) + 1
            self.presentNextPolicy(nextPolicy: nextPolicy, progress: progress)
        }
    }
}

// MARK: - ServiceTermsModalLoadTermsScreenCoordinatorDelegate
extension ServiceTermsModalCoordinator: ServiceTermsModalLoadTermsScreenCoordinatorDelegate {
    func serviceTermsModalLoadTermsScreenCoordinator(_ coordinator: ServiceTermsModalLoadTermsScreenCoordinatorType, didCompleteWithTerms terms: MXLoginTerms?) {
        guard let terms = terms else {
            self.processNextPolicy()
            return
        }

        self.policies = terms.policiesData(forLanguage: Bundle.mxk_language(), defaultLanguage: Bundle.mxk_fallbackLanguage())
        self.processNextPolicy()
    }

    func serviceTermsModalLoadTermsScreenCoordinatorDidCancel(_ coordinator: ServiceTermsModalLoadTermsScreenCoordinatorType) {
        self.delegate?.serviceTermsModalCoordinatorDidAccept(self)
    }
}

extension ServiceTermsModalCoordinator: ServiceTermsModalShowTermScreenCoordinatorDelegate {
    func serviceTermsModalShowTermScreenCoordinator(_ coordinator: ServiceTermsModalShowTermScreenCoordinatorType, didAcceptPolicy policy: MXLoginPolicyData) {
        self.acceptedPolicies.append(policy)
        self.processNextPolicy()
    }

    func serviceTermsModalShowTermScreenCoordinatorDidDecline(_ coordinator: ServiceTermsModalShowTermScreenCoordinatorType) {
        self.delegate?.serviceTermsModalCoordinatorDidDecline(self)
    }
}
