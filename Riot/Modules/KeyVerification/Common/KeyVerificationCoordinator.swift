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
final class KeyVerificationCoordinator: KeyVerificationCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    private let session: MXSession
    private let verificationFlow: KeyVerificationFlow
    private let verificationKind: KeyVerificationKind
    private let cancellable: Bool
    private weak var completeSecurityCoordinator: KeyVerificationSelfVerifyWaitCoordinatorType?
    
    private var otherUserId: String {
        
        let otherUserId: String
        
        switch self.verificationFlow {
        case .verifyUser(let roomMember):
            otherUserId = roomMember.userId
        case .verifyDevice(let userId, _):
            otherUserId = userId
        case .incomingRequest(let incomingKeyVerificationRequest):
            otherUserId = incomingKeyVerificationRequest.otherUser
        case .incomingSASTransaction(let incomingSASTransaction):
            otherUserId = incomingSASTransaction.otherUserId
        case .completeSecurity:
            otherUserId = self.session.myUser.userId
        }
        
        return otherUserId
    }
    
    private var otherDeviceId: String? {
        
        let otherDeviceId: String?
        
        switch self.verificationFlow {
        case .verifyUser:
            otherDeviceId = nil
        case .verifyDevice(_, let deviceId):
            otherDeviceId = deviceId
        case .incomingRequest(let incomingKeyVerificationRequest):
            otherDeviceId = incomingKeyVerificationRequest.otherDevice
        case .incomingSASTransaction(let incomingSASTransaction):
            otherDeviceId = incomingSASTransaction.otherDeviceId
        case .completeSecurity:
            otherDeviceId = nil
        }
        
        return otherDeviceId
    }
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: KeyVerificationCoordinatorDelegate?
    
    // MARK: - Setup
    
    /// Creates a key verification coordinator.
    ///
    /// - Parameters:
    ///   - session: The MXSession.
    ///   - flow: The wanted key verification flow.
    ///   - navigationRouter: Existing NavigationRouter from which present the flow (optional).
    ///   - cancellable: Whether key verification process can be cancelled.
    init(session: MXSession, flow: KeyVerificationFlow, navigationRouter: NavigationRouterType? = nil, cancellable: Bool) {
        self.navigationRouter = navigationRouter ?? NavigationRouter(navigationController: RiotNavigationController())
        
        self.session = session
        self.verificationFlow = flow
        
        let verificationKind: KeyVerificationKind
        
        switch flow {
        case .incomingRequest(let request):
            if request.isFromMyUser {
                // TODO: Check for .newSession case
                verificationKind = .otherSession
            } else {
                verificationKind = .user
            }
        case .verifyUser:
            verificationKind = .user
        case .completeSecurity:
            verificationKind = .thisSession
        case .verifyDevice:
            verificationKind = .otherSession
        case .incomingSASTransaction:
            verificationKind = .otherSession
        }
        
        self.verificationKind = verificationKind
        self.cancellable = cancellable
    }
    
    // MARK: - Public methods
    
    func start() {
        let rootCoordinator: Coordinator & Presentable

        switch self.verificationFlow {
        case .verifyUser(let roomMember):
            rootCoordinator = self.createUserVerificationStartCoordinator(with: roomMember)
        case .verifyDevice(let userId, let deviceId):
            if userId ==  self.session.myUser.userId {
                rootCoordinator = self.createSelfVerificationCoordinator(otherDeviceId: deviceId)
            } else {
                rootCoordinator = self.createDataLoadingScreenCoordinator(otherUserId: userId, otherDeviceId: deviceId)
            }
        case .incomingRequest(let incomingKeyVerificationRequest):
            rootCoordinator = self.createDataLoadingScreenCoordinator(with: incomingKeyVerificationRequest)
        case .incomingSASTransaction(let incomingSASTransaction):
            rootCoordinator = self.createDataLoadingScreenCoordinator(otherUserId: incomingSASTransaction.otherUserId, otherDeviceId: incomingSASTransaction.otherDeviceId)
        case .completeSecurity(let isNewSignIn):
            let coordinator = self.createCompleteSecurityCoordinator(isNewSignIn: isNewSignIn)
            self.completeSecurityCoordinator = coordinator
            rootCoordinator = coordinator
        }

        rootCoordinator.start()

        self.add(childCoordinator: rootCoordinator)

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
        return self.navigationRouter
            .toPresentable()
            .vc_setModalFullScreen(!self.cancellable)
    }
    
    // MARK: - Private methods
    
    private func didComplete() {
        self.delegate?.keyVerificationCoordinatorDidComplete(self, otherUserId: self.otherUserId, otherDeviceId: self.otherDeviceId ?? "")
    }
    
    private func didCancel() {
        // In the case of the complete security flow, come back to the root screen if any child flow
        // like device verification has been cancelled
        if self.completeSecurityCoordinator != nil && childCoordinators.count > 1 {
            MXLog.debug("[KeyVerificationCoordinator] didCancel: popToRootModule")
            self.navigationRouter.popToRootModule(animated: true)
            return
        }
        
        self.delegate?.keyVerificationCoordinatorDidCancel(self)
    }
    
    private func createCompleteSecurityCoordinator(isNewSignIn: Bool) -> KeyVerificationSelfVerifyWaitCoordinatorType {
        let coordinator = KeyVerificationSelfVerifyWaitCoordinator(session: self.session, isNewSignIn: isNewSignIn, cancellable: self.cancellable)
        coordinator.delegate = self
        coordinator.start()
        
        return coordinator
    }
    
    private func showSecretsRecovery(with recoveryMode: SecretsRecoveryMode) {
        let coordinator = SecretsRecoveryCoordinator(session: self.session, recoveryMode: recoveryMode, recoveryGoal: .verifyDevice, navigationRouter: self.navigationRouter, cancellable: self.cancellable)
        coordinator.delegate = self
        coordinator.start()
        
        self.add(childCoordinator: coordinator)
    }
    
    private func createSelfVerificationCoordinator(otherDeviceId: String) -> KeyVerificationSelfVerifyStartCoordinator {
        let coordinator = KeyVerificationSelfVerifyStartCoordinator(session: self.session, otherDeviceId: otherDeviceId)
        coordinator.delegate = self
        coordinator.start()
        
        return coordinator
    }

    private func createDataLoadingScreenCoordinator(otherUserId: String, otherDeviceId: String) -> KeyVerificationDataLoadingCoordinator {
        let coordinator = KeyVerificationDataLoadingCoordinator(session: self.session, verificationKind: self.verificationKind, otherUserId: otherUserId, otherDeviceId: otherDeviceId)
        coordinator.delegate = self
        coordinator.start()

        return coordinator
    }
    
    private func createDataLoadingScreenCoordinator(with keyVerificationRequest: MXKeyVerificationRequest) -> KeyVerificationDataLoadingCoordinator {
        let coordinator = KeyVerificationDataLoadingCoordinator(session: self.session, verificationKind: self.verificationKind, incomingKeyVerificationRequest: keyVerificationRequest)
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

    private func showIncoming(otherUser: MXUser, transaction: MXSASTransaction) {
        let coordinator = DeviceVerificationIncomingCoordinator(session: self.session, otherUser: otherUser, transaction: transaction)
        coordinator.delegate = self
        coordinator.start()

        self.add(childCoordinator: coordinator)
        self.navigationRouter.setRootModule(coordinator) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }

    private func showVerifyBySAS(transaction: MXSASTransaction, animated: Bool) {
        if navigationRouter.modules.last is KeyVerificationVerifyBySASCoordinator {
            return
        }
        let coordinator = KeyVerificationVerifyBySASCoordinator(session: self.session, transaction: transaction, verificationKind: self.verificationKind)
        coordinator.delegate = self
        coordinator.start()

        self.add(childCoordinator: coordinator)
        self.navigationRouter.push(coordinator, animated: animated) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    private func showVerifyByScanning(keyVerificationRequest: MXKeyVerificationRequest, animated: Bool) {
        let coordinator = KeyVerificationVerifyByScanningCoordinator(session: self.session, verificationKind: self.verificationKind, keyVerificationRequest: keyVerificationRequest)
        coordinator.delegate = self
        coordinator.start()
        
        self.add(childCoordinator: coordinator)
        self.navigationRouter.push(coordinator, animated: animated) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    private func showScanConfirmation(for transaction: MXQRCodeTransaction, codeScanning: KeyVerificationScanning, animated: Bool) {
        let coordinator = KeyVerificationScanConfirmationCoordinator(session: self.session, transaction: transaction, codeScanning: codeScanning, verificationKind: self.verificationKind)
        coordinator.delegate = self
        coordinator.start()
        
        self.add(childCoordinator: coordinator)
        self.navigationRouter.push(coordinator, animated: animated) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }

    private func showVerified(animated: Bool) {
        let viewController = KeyVerificationVerifiedViewController.instantiate(with: self.verificationKind)
        viewController.delegate = self
        self.navigationRouter.setRootModule(viewController)
    }
}

// MARK: - KeyVerificationDataLoadingCoordinatorDelegate
extension KeyVerificationCoordinator: KeyVerificationDataLoadingCoordinatorDelegate {
    
    func keyVerificationDataLoadingCoordinator(_ coordinator: KeyVerificationDataLoadingCoordinatorType, didAcceptKeyVerificationRequest keyVerificationRequest: MXKeyVerificationRequest) {
        self.showVerifyByScanning(keyVerificationRequest: keyVerificationRequest, animated: true)
    }
    
    func keyVerificationDataLoadingCoordinator(_ coordinator: KeyVerificationDataLoadingCoordinatorType, didLoadUser user: MXUser, device: MXDeviceInfo) {
        
        if case .incomingSASTransaction(let incomingTransaction) = self.verificationFlow {
            self.showIncoming(otherUser: user, transaction: incomingTransaction)
        } else {
            self.showStart(otherUser: user, otherDevice: device)
        }
    }
    
    func keyVerificationDataLoadingCoordinator(_ coordinator: KeyVerificationDataLoadingCoordinatorType, didAcceptKeyVerificationRequestWithTransaction transaction: MXKeyVerificationTransaction) {
        
        if let sasTransaction = transaction as? MXSASTransaction {
            self.showVerifyBySAS(transaction: sasTransaction, animated: true)
        } else {
            MXLog.debug("[KeyVerificationCoordinator] Transaction \(transaction) is not supported")
            self.didCancel()
        }
    }

    func keyVerificationDataLoadingCoordinatorDidCancel(_ coordinator: KeyVerificationDataLoadingCoordinatorType) {
        self.didCancel()
    }
}

// MARK: - DeviceVerificationStartCoordinatorDelegate
extension KeyVerificationCoordinator: DeviceVerificationStartCoordinatorDelegate {
    func deviceVerificationStartCoordinator(_ coordinator: DeviceVerificationStartCoordinatorType, otherDidAcceptRequest request: MXKeyVerificationRequest) {
        self.showVerifyByScanning(keyVerificationRequest: request, animated: true)
    }

    func deviceVerificationStartCoordinatorDidCancel(_ coordinator: DeviceVerificationStartCoordinatorType) {
        self.didCancel()
    }
}

// MARK: - DeviceVerificationIncomingCoordinatorDelegate
extension KeyVerificationCoordinator: DeviceVerificationIncomingCoordinatorDelegate {
    func deviceVerificationIncomingCoordinator(_ coordinator: DeviceVerificationIncomingCoordinatorType, didAcceptTransaction transaction: MXSASTransaction) {
        self.showVerifyBySAS(transaction: transaction, animated: true)
    }

    func deviceVerificationIncomingCoordinatorDidCancel(_ coordinator: DeviceVerificationIncomingCoordinatorType) {
        self.didCancel()
    }
}

// MARK: - KeyVerificationVerifyBySASCoordinatorDelegate
extension KeyVerificationCoordinator: KeyVerificationVerifyBySASCoordinatorDelegate {
    func keyVerificationVerifyBySASCoordinatorDidComplete(_ coordinator: KeyVerificationVerifyBySASCoordinatorType) {
        self.showVerified(animated: true)
    }

    func keyVerificationVerifyBySASCoordinatorDidCancel(_ coordinator: KeyVerificationVerifyBySASCoordinatorType) {
        self.didCancel()
    }
}

// MARK: - KeyVerificationVerifiedViewControllerDelegate
extension KeyVerificationCoordinator: KeyVerificationVerifiedViewControllerDelegate {
    func keyVerificationVerifiedViewControllerDidTapSetupAction(_ viewController: KeyVerificationVerifiedViewController) {
        self.didComplete()
    }

    func keyVerificationVerifiedViewControllerDidCancel(_ viewController: KeyVerificationVerifiedViewController) {
        self.didCancel()
    }
}

// MARK: - UserVerificationStartCoordinatorDelegate
extension KeyVerificationCoordinator: UserVerificationStartCoordinatorDelegate {
        
    func userVerificationStartCoordinator(_ coordinator: UserVerificationStartCoordinatorType, otherDidAcceptRequest request: MXKeyVerificationRequest) {
        self.showVerifyByScanning(keyVerificationRequest: request, animated: true)
    }
    
    func userVerificationStartCoordinator(_ coordinator: UserVerificationStartCoordinatorType, didCompleteWithOutgoingTransaction transaction: MXSASTransaction) {
        self.showVerifyBySAS(transaction: transaction, animated: true)
    }
    
    func userVerificationStartCoordinator(_ coordinator: UserVerificationStartCoordinatorType, didTransactionCancelled transaction: MXSASTransaction) {
        self.didCancel()
    }
    
    func userVerificationStartCoordinatorDidCancel(_ coordinator: UserVerificationStartCoordinatorType) {
        self.didCancel()
    }
}

// MARK: - KeyVerificationVerifyByScanningCoordinatorDelegate
extension KeyVerificationCoordinator: KeyVerificationVerifyByScanningCoordinatorDelegate {
    
    func keyVerificationVerifyByScanningCoordinatorDidCancel(_ coordinator: KeyVerificationVerifyByScanningCoordinatorType) {
         self.didCancel()
    }
    
    func keyVerificationVerifyByScanningCoordinator(_ coordinator: KeyVerificationVerifyByScanningCoordinatorType, didScanOtherQRCodeData qrCodeData: MXQRCodeData, withTransaction transaction: MXQRCodeTransaction) {
        self.showScanConfirmation(for: transaction, codeScanning: .scannedOtherQRCode(qrCodeData), animated: true)
    }
    
    func keyVerificationVerifyByScanningCoordinator(_ coordinator: KeyVerificationVerifyByScanningCoordinatorType, qrCodeDidScannedByOtherWithTransaction transaction: MXQRCodeTransaction) {
        self.showScanConfirmation(for: transaction, codeScanning: .myQRCodeScanned, animated: true)
    }    
    
    func keyVerificationVerifyByScanningCoordinator(_ coordinator: KeyVerificationVerifyByScanningCoordinatorType, didCompleteWithSASTransaction transaction: MXSASTransaction) {
        self.showVerifyBySAS(transaction: transaction, animated: true)
    }
}

// MARK: - KeyVerificationSelfVerifyStartCoordinatorDelegate
extension KeyVerificationCoordinator: KeyVerificationSelfVerifyStartCoordinatorDelegate {
    
    func keyVerificationSelfVerifyStartCoordinator(_ coordinator: KeyVerificationSelfVerifyStartCoordinatorType, otherDidAcceptRequest request: MXKeyVerificationRequest) {
        self.showVerifyByScanning(keyVerificationRequest: request, animated: true)
    }
    
    func keyVerificationSelfVerifyStartCoordinatorDidCancel(_ coordinator: KeyVerificationSelfVerifyStartCoordinatorType) {
        self.didCancel()
    }
}

// MARK: - KeyVerificationSelfVerifyWaitCoordinatorDelegate
extension KeyVerificationCoordinator: KeyVerificationSelfVerifyWaitCoordinatorDelegate {
    
    func keyVerificationSelfVerifyWaitCoordinator(_ coordinator: KeyVerificationSelfVerifyWaitCoordinatorType, didAcceptKeyVerificationRequest keyVerificationRequest: MXKeyVerificationRequest) {
        self.showVerifyByScanning(keyVerificationRequest: keyVerificationRequest, animated: true)
    }
    
    func keyVerificationSelfVerifyWaitCoordinator(_ coordinator: KeyVerificationSelfVerifyWaitCoordinatorType, didAcceptIncomingSASTransaction incomingSASTransaction: MXSASTransaction) {
        self.showVerifyBySAS(transaction: incomingSASTransaction, animated: true)                
    }
    
    func keyVerificationSelfVerifyWaitCoordinatorDidCancel(_ coordinator: KeyVerificationSelfVerifyWaitCoordinatorType) {
        self.didCancel()
    }
    
    func keyVerificationSelfVerifyWaitCoordinator(_ coordinator: KeyVerificationSelfVerifyWaitCoordinatorType, wantsToRecoverSecretsWith secretsRecoveryMode: SecretsRecoveryMode) {        
        self.showSecretsRecovery(with: secretsRecoveryMode)
    }
}

// MARK: - KeyVerificationScanConfirmationCoordinatorDelegate
extension KeyVerificationCoordinator: KeyVerificationScanConfirmationCoordinatorDelegate {
    
    func keyVerificationScanConfirmationCoordinatorDidComplete(_ coordinator: KeyVerificationScanConfirmationCoordinatorType) {
        self.showVerified(animated: true)
    }
    
    func keyVerificationScanConfirmationCoordinatorDidCancel(_ coordinator: KeyVerificationScanConfirmationCoordinatorType) {
        self.didCancel()
    }
}

// MARK: - SecretsRecoveryCoordinatorDelegate
extension KeyVerificationCoordinator: SecretsRecoveryCoordinatorDelegate {
    
    func secretsRecoveryCoordinatorDidRecover(_ coordinator: SecretsRecoveryCoordinatorType) {
        self.remove(childCoordinator: coordinator)
        self.showVerified(animated: true)
    }
    
    func secretsRecoveryCoordinatorDidCancel(_ coordinator: SecretsRecoveryCoordinatorType) {
        self.remove(childCoordinator: coordinator)
        self.didCancel()
    }
}
