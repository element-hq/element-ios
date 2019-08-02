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
    private var acceptedTermsUrls: [String]
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ServiceTermsModalCoordinatorDelegate?
    
    // MARK: - Setup
    init(session: MXSession, baseUrl: String, serviceType: MXServiceType, accessToken: String) {
        self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        self.session = session
        self.serviceTerms = MXServiceTerms(baseUrl: baseUrl, serviceType: serviceType, matrixSession: session, accessToken: accessToken)
        self.acceptedTermsUrls = []
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
        self.navigationRouter.setRootModule(coordinator)

        coordinator.start()
    }

    private func processNextPolicy() {
        guard let policies = self.policies else {
            print("[ServiceTermsModalCoordinator] processNextPolicy: No terms loaded. Leave")
            self.delegate?.serviceTermsModalCoordinatorDidCancel(self)
            return
        }

        if self.acceptedTermsUrls.count == policies.count {
            self.presentSaveScreen(acceptedTermsUrls: self.acceptedTermsUrls)
        } else {
            let nextPolicyIndex = self.acceptedTermsUrls.count

            let nextPolicy = policies[nextPolicyIndex]
            let progress = Progress(totalUnitCount: Int64(policies.count))
            progress.completedUnitCount = Int64(self.acceptedTermsUrls.count) + 1
            self.presentNextPolicy(nextPolicy: nextPolicy, progress: progress)
        }
    }

    private func createServiceTermsModalSaveTermsScreenCoordinator(acceptedTermsUrls: [String]) -> ServiceTermsModalSaveTermsScreenCoordinator {
        let coordinator = ServiceTermsModalSaveTermsScreenCoordinator(serviceTerms: self.serviceTerms, termsUrls: acceptedTermsUrls)
        coordinator.delegate = self
        return coordinator
    }

    private func presentSaveScreen(acceptedTermsUrls: [String]) {
        let coordinator = self.createServiceTermsModalSaveTermsScreenCoordinator(acceptedTermsUrls: acceptedTermsUrls)
        self.add(childCoordinator: coordinator)
        self.navigationRouter.setRootModule(coordinator)

        coordinator.start()
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
        self.acceptedTermsUrls.append(policy.url)
        self.processNextPolicy()
    }

    func serviceTermsModalShowTermScreenCoordinatorDidDecline(_ coordinator: ServiceTermsModalShowTermScreenCoordinatorType) {
        self.delegate?.serviceTermsModalCoordinatorDidDecline(self)
    }
}

extension ServiceTermsModalCoordinator: ServiceTermsModalSaveTermsScreenCoordinatorDelegate {
    func serviceTermsModalSaveTermsScreenCoordinatorDidComplete(_ coordinator: ServiceTermsModalSaveTermsScreenCoordinatorType) {
        self.delegate?.serviceTermsModalCoordinatorDidAccept(self)
    }

    func serviceTermsModalSaveTermsScreenCoordinatorDidCancel(_ coordinator: ServiceTermsModalSaveTermsScreenCoordinatorType) {
        self.delegate?.serviceTermsModalCoordinatorDidCancel(self)
    }
}
