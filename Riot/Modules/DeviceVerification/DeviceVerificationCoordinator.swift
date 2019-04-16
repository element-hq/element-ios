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

        guard let otherUser = self.session.user(withUserId: otherUserId) else {
            return // TODO
        }

        // Before starting make sure we have device crypto informatino
        self.session.crypto?.downloadKeys([self.otherUserId], forceDownload: false, success: { [weak self] (usersDevicesMap) in
            guard let sself = self else {
                return
            }

            guard let otherDevice = usersDevicesMap?.object(forDevice: sself.otherDeviceId, forUser: sself.otherUserId) else {
                return // TODO
            }

            var rootCoordinator: Coordinator & Presentable
            if let incomingTransaction = sself.incomingTransaction {
                let coordinator = sself.createDeviceVerificationIncomingCoordinator(otherUser: otherUser, transaction: incomingTransaction)
                coordinator.delegate = self
                rootCoordinator = coordinator
            } else {
                let coordinator = sself.createDeviceVerificationStartCoordinator(otherUser: otherUser, otherDevice: otherDevice)
                coordinator.delegate = self
                rootCoordinator = coordinator
            }

            // TODO: To remove. Only for dev
            //rootCoordinator = DeviceVerificationVerifyCoordinator(session: sself.session)
            //rootCoordinator.delegate = self

            rootCoordinator.start()

            sself.add(childCoordinator: rootCoordinator)
            sself.navigationRouter.setRootModule(rootCoordinator)

        }, failure: { (error) in
            // TODO
        })
      }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private methods

    private func createDeviceVerificationStartCoordinator(otherUser: MXUser, otherDevice: MXDeviceInfo) -> DeviceVerificationStartCoordinator {
        let coordinator = DeviceVerificationStartCoordinator(session: self.session, otherUser: otherUser, otherDevice: otherDevice)
        coordinator.delegate = self
        return coordinator
    }

    private func createDeviceVerificationIncomingCoordinator(otherUser: MXUser, transaction: MXIncomingSASTransaction) -> DeviceVerificationIncomingCoordinator {
        let coordinator = DeviceVerificationIncomingCoordinator(session: self.session, otherUser: otherUser, transaction: transaction)
        coordinator.delegate = self
        return coordinator
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

extension DeviceVerificationCoordinator: DeviceVerificationStartCoordinatorDelegate {
    func deviceVerificationStartCoordinator(_ coordinator: DeviceVerificationStartCoordinatorType, didCompleteWithOutgoingTransaction transaction: MXSASTransaction) {
        self.showVerify(transaction: transaction, animated: true)
    }

    func deviceVerificationStartCoordinator(_ coordinator: DeviceVerificationStartCoordinatorType, didTransactionCancelled transaction: MXSASTransaction) {
        self.delegate?.deviceVerificationCoordinatorDidComplete(self)
    }

    func deviceVerificationStartCoordinatorDidCancel(_ coordinator: DeviceVerificationStartCoordinatorType) {
        self.delegate?.deviceVerificationCoordinatorDidComplete(self)
    }
}

extension DeviceVerificationCoordinator: DeviceVerificationIncomingCoordinatorDelegate {
    func deviceVerificationIncomingCoordinator(_ coordinator: DeviceVerificationIncomingCoordinatorType, didAcceptTransaction transaction: MXSASTransaction) {
        self.showVerify(transaction: transaction, animated: true)
    }

    func deviceVerificationIncomingCoordinatorDidCancel(_ coordinator: DeviceVerificationIncomingCoordinatorType) {
        self.delegate?.deviceVerificationCoordinatorDidComplete(self)
    }
}

extension DeviceVerificationCoordinator: DeviceVerificationVerifyCoordinatorDelegate {
    func deviceVerificationVerifyCoordinatorDidComplete(_ coordinator: DeviceVerificationVerifyCoordinatorType) {
        self.showVerified(animated: true)
    }

    func deviceVerificationVerifyCoordinatorDidCancel(_ coordinator: DeviceVerificationVerifyCoordinatorType) {
        self.delegate?.deviceVerificationCoordinatorDidComplete(self)
    }
}

extension DeviceVerificationCoordinator: DeviceVerificationVerifiedViewControllerDelegate {
    func deviceVerificationVerifiedViewControllerDidTapSetupAction(_ viewController: DeviceVerificationVerifiedViewController) {
        self.delegate?.deviceVerificationCoordinatorDidComplete(self)
    }

    func deviceVerificationVerifiedViewControllerDidCancel(_ viewController: DeviceVerificationVerifiedViewController) {
        self.delegate?.deviceVerificationCoordinatorDidComplete(self)
    }
}
