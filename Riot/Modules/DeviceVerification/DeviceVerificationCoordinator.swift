// File created from FlowTemplate
// $ createRootCoordinator.sh DeviceVerification DeviceVerification DeviceVerificationStart
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
final class DeviceVerificationCoordinator: DeviceVerificationCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    private let session: MXSession
    private let otherUserId: String
    private let otherDeviceId: String

    private var incomingTransaction: MXIncomingSASTransaction?

    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: DeviceVerificationCoordinatorDelegate?
    
    // MARK: - Setup

    /// Contrustor to start a verification of another device.
    ///
    /// - Parameters:
    ///   - session: the MXSession
    ///   - otherUserId: the device user id
    ///   - otherDevice: the device id
    init(session: MXSession, otherUserId: String, otherDeviceId: String) {
        self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        self.session = session
        self.otherUserId = otherUserId
        self.otherDeviceId = otherDeviceId
    }

    /// Contrustor to manage an incoming SAS device verification transaction
    ///
    /// - Parameters:
    ///   - session: the MXSession
    ///   - transaction: an existing device verification transaction
    convenience init(session: MXSession, incomingTransaction: MXIncomingSASTransaction) {
        self.init(session: session,
                  otherUserId: incomingTransaction.otherUserId,
                  otherDeviceId: incomingTransaction.otherDeviceId)
        self.incomingTransaction = incomingTransaction
    }
    
    // MARK: - Public methods
    
    func start() {
        let rootCoordinator = self.createDataLoadingScreenCoordinator()
        rootCoordinator.start()

        self.add(childCoordinator: rootCoordinator)
        self.navigationRouter.setRootModule(rootCoordinator) { [weak self] in
            self?.remove(childCoordinator: rootCoordinator)
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private methods

    private func createDataLoadingScreenCoordinator() -> DeviceVerificationDataLoadingCoordinator {
        let coordinator = DeviceVerificationDataLoadingCoordinator(session: self.session, otherUserId: self.otherUserId, otherDeviceId: self.otherDeviceId)
        coordinator.delegate = self
        coordinator.start()

        return coordinator
    }

    private func showStart(otherUser: MXUser, otherDevice: MXDeviceInfo) {
        let coordinator = DeviceVerificationStartCoordinator(session: self.session, otherUser: otherUser, otherDevice: otherDevice)
        coordinator.delegate = self
        coordinator.start()

        self.add(childCoordinator: coordinator)
        self.navigationRouter.setRootModule(coordinator) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }

    private func showIncoming(otherUser: MXUser, transaction: MXIncomingSASTransaction) {
        let coordinator = DeviceVerificationIncomingCoordinator(session: self.session, otherUser: otherUser, transaction: transaction)
        coordinator.delegate = self
        coordinator.start()

        self.add(childCoordinator: coordinator)
        self.navigationRouter.setRootModule(coordinator) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }

    private func showVerify(transaction: MXSASTransaction, animated: Bool) {
        let coordinator = DeviceVerificationVerifyCoordinator(session: self.session, transaction: transaction)
        coordinator.delegate = self
        coordinator.start()

        self.add(childCoordinator: coordinator)
        self.navigationRouter.push(coordinator, animated: animated) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }

    private func showVerified(animated: Bool) {
        let viewController = DeviceVerificationVerifiedViewController.instantiate()
        viewController.delegate = self
        self.navigationRouter.setRootModule(viewController)
    }
}

extension DeviceVerificationCoordinator: DeviceVerificationDataLoadingCoordinatorDelegate {
    func deviceVerificationDataLoadingCoordinator(_ coordinator: DeviceVerificationDataLoadingCoordinatorType, didLoadUser user: MXUser, device: MXDeviceInfo) {

        if let incomingTransaction = self.incomingTransaction {
            self.showIncoming(otherUser: user, transaction: incomingTransaction)
        } else {
            self.showStart(otherUser: user, otherDevice: device)
        }
    }

    func deviceVerificationDataLoadingCoordinatorDidCancel(_ coordinator: DeviceVerificationDataLoadingCoordinatorType) {
        self.delegate?.deviceVerificationCoordinatorDidComplete(self, otherUserId: self.otherUserId, otherDeviceId: self.otherDeviceId)
    }
}

extension DeviceVerificationCoordinator: DeviceVerificationStartCoordinatorDelegate {
    func deviceVerificationStartCoordinator(_ coordinator: DeviceVerificationStartCoordinatorType, didCompleteWithOutgoingTransaction transaction: MXSASTransaction) {
        self.showVerify(transaction: transaction, animated: true)
    }

    func deviceVerificationStartCoordinator(_ coordinator: DeviceVerificationStartCoordinatorType, didTransactionCancelled transaction: MXSASTransaction) {
        self.delegate?.deviceVerificationCoordinatorDidComplete(self, otherUserId: self.otherUserId, otherDeviceId: self.otherDeviceId)
    }

    func deviceVerificationStartCoordinatorDidCancel(_ coordinator: DeviceVerificationStartCoordinatorType) {
        self.delegate?.deviceVerificationCoordinatorDidComplete(self, otherUserId: self.otherUserId, otherDeviceId: self.otherDeviceId)
    }
}

extension DeviceVerificationCoordinator: DeviceVerificationIncomingCoordinatorDelegate {
    func deviceVerificationIncomingCoordinator(_ coordinator: DeviceVerificationIncomingCoordinatorType, didAcceptTransaction transaction: MXSASTransaction) {
        self.showVerify(transaction: transaction, animated: true)
    }

    func deviceVerificationIncomingCoordinatorDidCancel(_ coordinator: DeviceVerificationIncomingCoordinatorType) {
        self.delegate?.deviceVerificationCoordinatorDidComplete(self, otherUserId: self.otherUserId, otherDeviceId: self.otherDeviceId)
    }
}

extension DeviceVerificationCoordinator: DeviceVerificationVerifyCoordinatorDelegate {
    func deviceVerificationVerifyCoordinatorDidComplete(_ coordinator: DeviceVerificationVerifyCoordinatorType) {
        self.showVerified(animated: true)
    }

    func deviceVerificationVerifyCoordinatorDidCancel(_ coordinator: DeviceVerificationVerifyCoordinatorType) {
        self.delegate?.deviceVerificationCoordinatorDidComplete(self, otherUserId: self.otherUserId, otherDeviceId: self.otherDeviceId)
    }
}

extension DeviceVerificationCoordinator: DeviceVerificationVerifiedViewControllerDelegate {
    func deviceVerificationVerifiedViewControllerDidTapSetupAction(_ viewController: DeviceVerificationVerifiedViewController) {
        self.delegate?.deviceVerificationCoordinatorDidComplete(self, otherUserId: self.otherUserId, otherDeviceId: self.otherDeviceId)
    }

    func deviceVerificationVerifiedViewControllerDidCancel(_ viewController: DeviceVerificationVerifiedViewController) {
        self.delegate?.deviceVerificationCoordinatorDidComplete(self, otherUserId: self.otherUserId, otherDeviceId: self.otherDeviceId)
    }
}
