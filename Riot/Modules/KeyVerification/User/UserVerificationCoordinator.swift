// File created from FlowTemplate
// $ createRootCoordinator.sh UserVerification UserVerification
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
final class UserVerificationCoordinator: NSObject, UserVerificationCoordinatorType {
    // MARK: - Properties
    
    // MARK: Private
    
    private let presenter: Presentable
    private let navigationRouter: NavigationRouterType
    private let session: MXSession
    private let userId: String
    private let userDisplayName: String?
    private var deviceId: String?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: UserVerificationCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(presenter: Presentable, session: MXSession, userId: String, userDisplayName: String?) {
        self.presenter = presenter
        navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        self.session = session
        self.userId = userId
        self.userDisplayName = userDisplayName
    }
    
    convenience init(presenter: Presentable, session: MXSession, userId: String, userDisplayName: String?, deviceId: String) {
        self.init(presenter: presenter, session: session, userId: userId, userDisplayName: userDisplayName)
        self.deviceId = deviceId
    }
    
    // MARK: - Public methods
    
    func start() {
        // Do not start again if existing coordinators are presented
        guard childCoordinators.isEmpty else {
            return
        }
        
        guard session.crypto.crossSigning.canCrossSign else {
            presentBootstrapNotSetup()
            return
        }
        
        let rootCoordinator: Coordinator & Presentable
        
        if let deviceId = deviceId {
            rootCoordinator = createSessionStatusCoordinator(with: deviceId, for: userId, userDisplayName: userDisplayName)
        } else {
            rootCoordinator = createUserVerificationSessionsStatusCoordinator()
        }
        
        rootCoordinator.start()

        add(childCoordinator: rootCoordinator)
        
        navigationRouter.setRootModule(rootCoordinator, hideNavigationBar: true, animated: false, popCompletion: {
            self.remove(childCoordinator: rootCoordinator)
        })
        
        let rootViewController = navigationRouter.toPresentable()
        rootViewController.modalPresentationStyle = .formSheet
        
        presenter.toPresentable().present(rootViewController, animated: true, completion: nil)
    }
    
    func toPresentable() -> UIViewController {
        navigationRouter.toPresentable()
    }
    
    // MARK: - Private methods
    
    private func createUserVerificationSessionsStatusCoordinator() -> UserVerificationSessionsStatusCoordinator {
        let coordinator = UserVerificationSessionsStatusCoordinator(session: session, userId: userId)
        coordinator.delegate = self
        return coordinator
    }
    
    private func createSessionStatusCoordinator(with deviceId: String, for userId: String, userDisplayName: String?) -> UserVerificationSessionStatusCoordinator {
        let coordinator = UserVerificationSessionStatusCoordinator(session: session, userId: userId, userDisplayName: userDisplayName, deviceId: deviceId)
        coordinator.delegate = self
        return coordinator
    }
    
    private func presentSessionStatus(with deviceId: String, for userId: String, userDisplayName: String?) {
        let coordinator = createSessionStatusCoordinator(with: deviceId, for: userId, userDisplayName: userDisplayName)
        coordinator.start()
        
        navigationRouter.push(coordinator, animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
    
    private func presentDeviceVerification(for deviceId: String) {
        let keyVerificationCoordinator = KeyVerificationCoordinator(session: session, flow: .verifyDevice(userId: userId, deviceId: deviceId), navigationRouter: navigationRouter, cancellable: true)
        keyVerificationCoordinator.delegate = self
        keyVerificationCoordinator.start()
        
        add(childCoordinator: keyVerificationCoordinator)
        
        navigationRouter.push(keyVerificationCoordinator, animated: true, popCompletion: {
            self.remove(childCoordinator: keyVerificationCoordinator)
        })
    }
    
    private func presentBootstrapNotSetup() {
        let alert = UIAlertController(title: VectorL10n.keyVerificationBootstrapNotSetupTitle,
                                      message: VectorL10n.keyVerificationBootstrapNotSetupMessage,
                                      preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: VectorL10n.ok, style: .cancel)
        alert.addAction(cancelAction)
        
        presenter.toPresentable().present(alert, animated: true, completion: nil)
    }
    
    private func presentManualDeviceVerification(for deviceId: String, of userId: String) {
        let coordinator = KeyVerificationManuallyVerifyCoordinator(session: session, deviceId: deviceId, userId: userId)
        coordinator.delegate = self
        coordinator.start()
        
        navigationRouter.push(coordinator, animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
}

// MARK: - UserVerificationSessionsStatusCoordinatorDelegate

extension UserVerificationCoordinator: UserVerificationSessionsStatusCoordinatorDelegate {
    func userVerificationSessionsStatusCoordinatorDidClose(_ coordinator: UserVerificationSessionsStatusCoordinatorType) {
        presenter.toPresentable().dismiss(animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
    
    func userVerificationSessionsStatusCoordinator(_ coordinator: UserVerificationSessionsStatusCoordinatorType, didSelectDeviceWithId deviceId: String, for userId: String) {
        presentSessionStatus(with: deviceId, for: userId, userDisplayName: userDisplayName)
    }
}

// MARK: - UserVerificationSessionStatusCoordinatorDelegate

extension UserVerificationCoordinator: UserVerificationSessionStatusCoordinatorDelegate {
    func userVerificationSessionStatusCoordinator(_ coordinator: UserVerificationSessionStatusCoordinatorType, wantsToVerifyDeviceWithId deviceId: String, for userId: String) {
        presentDeviceVerification(for: deviceId)
    }
    
    func userVerificationSessionStatusCoordinator(_ coordinator: UserVerificationSessionStatusCoordinatorType, wantsToManuallyVerifyDeviceWithId deviceId: String, for userId: String) {
        presentManualDeviceVerification(for: deviceId, of: userId)
    }
    
    func userVerificationSessionStatusCoordinatorDidClose(_ coordinator: UserVerificationSessionStatusCoordinatorType) {
        presenter.toPresentable().dismiss(animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
}

// MARK: - UserVerificationCoordinatorDelegate

extension UserVerificationCoordinator: KeyVerificationCoordinatorDelegate {
    func keyVerificationCoordinatorDidComplete(_ coordinator: KeyVerificationCoordinatorType, otherUserId: String, otherDeviceId: String) {
        dismissPresenter(coordinator: coordinator)
    }
    
    func keyVerificationCoordinatorDidCancel(_ coordinator: KeyVerificationCoordinatorType) {
        dismissPresenter(coordinator: coordinator)
    }
    
    func dismissPresenter(coordinator: KeyVerificationCoordinatorType) {
        presenter.toPresentable().dismiss(animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
}

// MARK: - KeyVerificationManuallyVerifyCoordinatorDelegate

extension UserVerificationCoordinator: KeyVerificationManuallyVerifyCoordinatorDelegate {
    func keyVerificationManuallyVerifyCoordinator(_ coordinator: KeyVerificationManuallyVerifyCoordinatorType, didVerifiedDeviceWithId deviceId: String, of userId: String) {
        presenter.toPresentable().dismiss(animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
    
    func keyVerificationManuallyVerifyCoordinatorDidCancel(_ coordinator: KeyVerificationManuallyVerifyCoordinatorType) {
        presenter.toPresentable().dismiss(animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
}
