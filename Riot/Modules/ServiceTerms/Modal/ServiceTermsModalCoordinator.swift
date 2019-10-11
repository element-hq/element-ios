// File created from FlowTemplate
// $ createRootCoordinator.sh Modal ServiceTermsModal ServiceTermsModalScreen
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
    private let outOfContext: Bool
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ServiceTermsModalCoordinatorDelegate?
    
    // MARK: - Setup
    init(session: MXSession, baseUrl: String, serviceType: MXServiceType, outOfContext: Bool, accessToken: String) {
        self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        self.session = session
        self.serviceTerms = MXServiceTerms(baseUrl: baseUrl, serviceType: serviceType, matrixSession: session, accessToken: accessToken)
        self.outOfContext = outOfContext
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

    private func createServiceTermsModalLoadTermsScreenCoordinator() -> ServiceTermsModalScreenCoordinator {
        let coordinator = ServiceTermsModalScreenCoordinator(serviceTerms: self.serviceTerms, outOfContext: self.outOfContext)
        coordinator.delegate = self
        return coordinator
    }

    private func showPolicy(policy: MXLoginPolicyData) {
        // Display the policy webpage into our webview
        let webViewViewController: WebViewViewController = WebViewViewController(url: policy.url)
        webViewViewController.title = policy.name

        let leftBarButtonItem: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_icon"), style: .plain, target: self, action: #selector(didTapCancelOnPolicyScreen))
        webViewViewController.navigationItem.leftBarButtonItem = leftBarButtonItem

        self.navigationRouter.push(webViewViewController, animated: true, popCompletion: nil)
    }

    private func removePolicyScreen() {
        self.navigationRouter.popModule(animated: true)
    }

    @objc private func didTapCancelOnPolicyScreen() {
        self.removePolicyScreen()
    }
}

// MARK: - ServiceTermsModalLoadTermsScreenCoordinatorDelegate
extension ServiceTermsModalCoordinator: ServiceTermsModalScreenCoordinatorDelegate {

    func serviceTermsModalScreenCoordinatorDidAccept(_ coordinator: ServiceTermsModalScreenCoordinatorType) {
        self.delegate?.serviceTermsModalCoordinatorDidAccept(self)
    }

    func serviceTermsModalScreenCoordinator(_ coordinator: ServiceTermsModalScreenCoordinatorType, displayPolicy policy: MXLoginPolicyData) {
        self.showPolicy(policy: policy)
    }

    func serviceTermsModalScreenCoordinatorDidDecline(_ coordinator: ServiceTermsModalScreenCoordinatorType) {
        self.delegate?.serviceTermsModalCoordinatorDidDecline(self)
    }

    func serviceTermsModalScreenCoordinatorDidCancel(_ coordinator: ServiceTermsModalScreenCoordinatorType) {
        self.delegate?.serviceTermsModalCoordinatorDidCancel(self)
    }
}
