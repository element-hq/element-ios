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
        self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
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
        guard self.childCoordinators.isEmpty else {
            return
        }
        
        guard self.session.crypto.crossSigning.canCrossSign  else {
            self.presentBootstrapNotSetup()
            return
        }
        
        let rootCoordinator: Coordinator & Presentable
        
        if let deviceId = self.deviceId {
            rootCoordinator = self.createSessionStatusCoordinator(with: deviceId, for: self.userId, userDisplayName: self.userDisplayName)
        } else {
            rootCoordinator = self.createUserVerificationSessionsStatusCoordinator()
        }
        
        rootCoordinator.start()

        self.add(childCoordinator: rootCoordinator)
        
        self.navigationRouter.setRootModule(rootCoordinator, hideNavigationBar: true, animated: false, popCompletion: {
            self.remove(childCoordinator: rootCoordinator)
        })
        
        let rootViewController = self.navigationRouter.toPresentable()
        rootViewController.modalPresentationStyle = .formSheet
        
        self.presenter.toPresentable().present(rootViewController, animated: true, completion: nil)
    }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private methods
    
    private func createUserVerificationSessionsStatusCoordinator() -> UserVerificationSessionsStatusCoordinator {
        let coordinator = UserVerificationSessionsStatusCoordinator(session: self.session, userId: self.userId)
        coordinator.delegate = self
        return coordinator
    }
    
    private func createSessionStatusCoordinator(with deviceId: String, for userId: String, userDisplayName: String?) -> UserVerificationSessionStatusCoordinator {
        let coordinator = UserVerificationSessionStatusCoordinator(session: self.session, userId: userId, userDisplayName: userDisplayName, deviceId: deviceId)
        coordinator.delegate = self
        return coordinator
    }
    
    private func presentSessionStatus(with deviceId: String, for userId: String, userDisplayName: String?) {
        let coordinator = self.createSessionStatusCoordinator(with: deviceId, for: userId, userDisplayName: userDisplayName)
        coordinator.start()
        
        self.navigationRouter.push(coordinator, animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
    
    private func presentDeviceVerification(for deviceId: String) {
        
        let keyVerificationCoordinator = KeyVerificationCoordinator(session: self.session, flow: .verifyDevice(userId: self.userId, deviceId: deviceId), navigationRouter: self.navigationRouter, cancellable: true)
        keyVerificationCoordinator.delegate = self
        keyVerificationCoordinator.start()
        
        self.add(childCoordinator: keyVerificationCoordinator)
        
        self.navigationRouter.push(keyVerificationCoordinator, animated: true, popCompletion: {
            self.remove(childCoordinator: keyVerificationCoordinator)
        })
    }
    
    private func presentBootstrapNotSetup() {
        let alert = UIAlertController(title: VectorL10n.keyVerificationBootstrapNotSetupTitle,
                                      message: VectorL10n.keyVerificationBootstrapNotSetupMessage,
                                      preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: VectorL10n.ok, style: .cancel)
        alert.addAction(cancelAction)
        
        self.presenter.toPresentable().present(alert, animated: true, completion: nil)        
    }
    
    private func presentManualDeviceVerification(for deviceId: String, of userId: String) {
        let coordinator = KeyVerificationManuallyVerifyCoordinator(session: self.session, deviceId: deviceId, userId: userId)
        coordinator.delegate = self
        coordinator.start()
        
        self.navigationRouter.push(coordinator, animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
}

// MARK: - UserVerificationSessionsStatusCoordinatorDelegate
extension UserVerificationCoordinator: UserVerificationSessionsStatusCoordinatorDelegate {
    func userVerificationSessionsStatusCoordinatorDidClose(_ coordinator: UserVerificationSessionsStatusCoordinatorType) {
        
        self.presenter.toPresentable().dismiss(animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
    
    func userVerificationSessionsStatusCoordinator(_ coordinator: UserVerificationSessionsStatusCoordinatorType, didSelectDeviceWithId deviceId: String, for userId: String) {
        self.presentSessionStatus(with: deviceId, for: userId, userDisplayName: self.userDisplayName)
    }
}

// MARK: - UserVerificationSessionStatusCoordinatorDelegate
extension UserVerificationCoordinator: UserVerificationSessionStatusCoordinatorDelegate {
    
    func userVerificationSessionStatusCoordinator(_ coordinator: UserVerificationSessionStatusCoordinatorType, wantsToVerifyDeviceWithId deviceId: String, for userId: String) {
        self.presentDeviceVerification(for: deviceId)
    }
    
    func userVerificationSessionStatusCoordinator(_ coordinator: UserVerificationSessionStatusCoordinatorType, wantsToManuallyVerifyDeviceWithId deviceId: String, for userId: String) {
        self.presentManualDeviceVerification(for: deviceId, of: userId)
    }
    
    func userVerificationSessionStatusCoordinatorDidClose(_ coordinator: UserVerificationSessionStatusCoordinatorType) {
        
        self.presenter.toPresentable().dismiss(animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
}

// MARK: - UserVerificationCoordinatorDelegate
extension UserVerificationCoordinator: KeyVerificationCoordinatorDelegate {
    
    func keyVerificationCoordinatorDidComplete(_ coordinator: KeyVerificationCoordinatorType, otherUserId: String, otherDeviceId: String) {
        dismissPresenter(coordinator: coordinator)
        delegate?.userVerificationCoordinatorDidComplete(self)
    }
    
    func keyVerificationCoordinatorDidCancel(_ coordinator: KeyVerificationCoordinatorType) {
        dismissPresenter(coordinator: coordinator)
    }
    
    func dismissPresenter(coordinator: KeyVerificationCoordinatorType) {
        self.presenter.toPresentable().dismiss(animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
}

// MARK: - KeyVerificationManuallyVerifyCoordinatorDelegate
extension UserVerificationCoordinator: KeyVerificationManuallyVerifyCoordinatorDelegate {
    
    func keyVerificationManuallyVerifyCoordinator(_ coordinator: KeyVerificationManuallyVerifyCoordinatorType, didVerifiedDeviceWithId deviceId: String, of userId: String) {
        self.presenter.toPresentable().dismiss(animated: true) {
            self.remove(childCoordinator: coordinator)
        }
        delegate?.userVerificationCoordinatorDidComplete(self)
    }
    
    func keyVerificationManuallyVerifyCoordinatorDidCancel(_ coordinator: KeyVerificationManuallyVerifyCoordinatorType) {
        self.presenter.toPresentable().dismiss(animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
}
