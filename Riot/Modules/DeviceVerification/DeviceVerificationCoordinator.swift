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
    private var incomingKeyVerificationRequest: MXKeyVerificationRequest?
    
    var roomMember: MXRoomMember?

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
    
    /// Contrustor to manage an incoming SAS device verification transaction
    ///
    /// - Parameters:
    ///   - session: the MXSession
    ///   - incomingKeyVerificationRequest: An existing incoming key verification request to accept
    convenience init(session: MXSession, incomingKeyVerificationRequest: MXKeyVerificationRequest) {
        self.init(session: session, otherUserId: incomingKeyVerificationRequest.sender, otherDeviceId: incomingKeyVerificationRequest.fromDevice)
        self.incomingKeyVerificationRequest = incomingKeyVerificationRequest
    }
    
    /// Constructor to start a user verification.
    ///
    /// - Parameters:
    ///   - session: the MXSession
    ///   - roomMember: an other room member
    init(session: MXSession, roomMember: MXRoomMember) {
        self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        self.session = session
        self.otherUserId = roomMember.userId
        self.otherDeviceId = ""
        self.roomMember = roomMember
    }
    
    // MARK: - Public methods
    
    func start() {
        let rootCoordinator: Coordinator & Presentable            
        
        if let incomingKeyVerificationRequest = self.incomingKeyVerificationRequest {
            rootCoordinator = self.createDataLoadingScreenCoordinator(with: incomingKeyVerificationRequest)
        } else if let roomMember = self.roomMember {
            rootCoordinator = self.createUserVerificationStartCoordinator(with: roomMember)
        } else {
            rootCoordinator = self.createDataLoadingScreenCoordinator()
        }
        
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
    
    private func createDataLoadingScreenCoordinator(with keyVerificationRequest: MXKeyVerificationRequest) -> DeviceVerificationDataLoadingCoordinator {
        let coordinator = DeviceVerificationDataLoadingCoordinator(incomingKeyVerificationRequest: keyVerificationRequest)
        coordinator.delegate = self
        coordinator.start()
        
        return coordinator
    }
    
    private func createUserVerificationStartCoordinator(with roomMember: MXRoomMember) -> UserVerificationStartCoordinator {
        let coordinator = UserVerificationStartCoordinator(session: self.session, roomMember: roomMember)
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
    
    func deviceVerificationDataLoadingCoordinator(_ coordinator: DeviceVerificationDataLoadingCoordinatorType, didAcceptKeyVerificationRequestWithTransaction transaction: MXDeviceVerificationTransaction) {
        
        if let sasTransaction = transaction as? MXSASTransaction {
            self.showVerify(transaction: sasTransaction, animated: true)
        } else {
            NSLog("[DeviceVerificationCoordinator] Transaction \(transaction) is not supported")
            self.delegate?.deviceVerificationCoordinatorDidComplete(self, otherUserId: self.otherUserId, otherDeviceId: self.otherDeviceId)
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

extension DeviceVerificationCoordinator: UserVerificationStartCoordinatorDelegate {
    func userVerificationStartCoordinator(_ coordinator: UserVerificationStartCoordinatorType, didCompleteWithOutgoingTransaction transaction: MXSASTransaction) {
        self.showVerify(transaction: transaction, animated: true)
    }
    
    func userVerificationStartCoordinator(_ coordinator: UserVerificationStartCoordinatorType, didTransactionCancelled transaction: MXSASTransaction) {
        self.delegate?.deviceVerificationCoordinatorDidComplete(self, otherUserId: self.otherUserId, otherDeviceId: self.otherDeviceId)
    }
    
    func userVerificationStartCoordinatorDidCancel(_ coordinator: UserVerificationStartCoordinatorType) {
        self.delegate?.deviceVerificationCoordinatorDidComplete(self, otherUserId: self.otherUserId, otherDeviceId: self.otherDeviceId)
    }
}
