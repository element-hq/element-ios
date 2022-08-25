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
        
        switch verificationFlow {
        case .verifyUser(let roomMember):
            otherUserId = roomMember.userId
        case .verifyDevice(let userId, _):
            otherUserId = userId
        case .incomingRequest(let incomingKeyVerificationRequest):
            otherUserId = incomingKeyVerificationRequest.otherUser
        case .incomingSASTransaction(let incomingSASTransaction):
            otherUserId = incomingSASTransaction.otherUserId
        case .completeSecurity:
            otherUserId = session.myUser.userId
        }
        
        return otherUserId
    }
    
    private var otherDeviceId: String? {
        let otherDeviceId: String?
        
        switch verificationFlow {
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
        verificationFlow = flow
        
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

        switch verificationFlow {
        case .verifyUser(let roomMember):
            rootCoordinator = createUserVerificationStartCoordinator(with: roomMember)
        case .verifyDevice(let userId, let deviceId):
            if userId == session.myUser.userId {
                rootCoordinator = createSelfVerificationCoordinator(otherDeviceId: deviceId)
            } else {
                rootCoordinator = createDataLoadingScreenCoordinator(otherUserId: userId, otherDeviceId: deviceId)
            }
        case .incomingRequest(let incomingKeyVerificationRequest):
            rootCoordinator = createDataLoadingScreenCoordinator(with: incomingKeyVerificationRequest)
        case .incomingSASTransaction(let incomingSASTransaction):
            rootCoordinator = createDataLoadingScreenCoordinator(otherUserId: incomingSASTransaction.otherUserId, otherDeviceId: incomingSASTransaction.otherDeviceId)
        case .completeSecurity(let isNewSignIn):
            let coordinator = createCompleteSecurityCoordinator(isNewSignIn: isNewSignIn)
            completeSecurityCoordinator = coordinator
            rootCoordinator = coordinator
        }

        rootCoordinator.start()

        add(childCoordinator: rootCoordinator)

        if navigationRouter.modules.isEmpty == false {
            navigationRouter.push(rootCoordinator, animated: true, popCompletion: { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
            })
        } else {
            navigationRouter.setRootModule(rootCoordinator) { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        navigationRouter
            .toPresentable()
            .vc_setModalFullScreen(!cancellable)
    }
    
    // MARK: - Private methods
    
    private func didComplete() {
        delegate?.keyVerificationCoordinatorDidComplete(self, otherUserId: otherUserId, otherDeviceId: otherDeviceId ?? "")
    }
    
    private func didCancel() {
        // In the case of the complete security flow, come back to the root screen if any child flow
        // like device verification has been cancelled
        if completeSecurityCoordinator != nil, childCoordinators.count > 1 {
            MXLog.debug("[KeyVerificationCoordinator] didCancel: popToRootModule")
            navigationRouter.popToRootModule(animated: true)
            return
        }
        
        delegate?.keyVerificationCoordinatorDidCancel(self)
    }
    
    private func createCompleteSecurityCoordinator(isNewSignIn: Bool) -> KeyVerificationSelfVerifyWaitCoordinatorType {
        let coordinator = KeyVerificationSelfVerifyWaitCoordinator(session: session, isNewSignIn: isNewSignIn, cancellable: cancellable)
        coordinator.delegate = self
        coordinator.start()
        
        return coordinator
    }
    
    private func showSecretsRecovery(with recoveryMode: SecretsRecoveryMode) {
        let coordinator = SecretsRecoveryCoordinator(session: session, recoveryMode: recoveryMode, recoveryGoal: .verifyDevice, navigationRouter: navigationRouter, cancellable: cancellable)
        coordinator.delegate = self
        coordinator.start()
        
        add(childCoordinator: coordinator)
    }
    
    private func createSelfVerificationCoordinator(otherDeviceId: String) -> KeyVerificationSelfVerifyStartCoordinator {
        let coordinator = KeyVerificationSelfVerifyStartCoordinator(session: session, otherDeviceId: otherDeviceId)
        coordinator.delegate = self
        coordinator.start()
        
        return coordinator
    }

    private func createDataLoadingScreenCoordinator(otherUserId: String, otherDeviceId: String) -> KeyVerificationDataLoadingCoordinator {
        let coordinator = KeyVerificationDataLoadingCoordinator(session: session, verificationKind: verificationKind, otherUserId: otherUserId, otherDeviceId: otherDeviceId)
        coordinator.delegate = self
        coordinator.start()

        return coordinator
    }
    
    private func createDataLoadingScreenCoordinator(with keyVerificationRequest: MXKeyVerificationRequest) -> KeyVerificationDataLoadingCoordinator {
        let coordinator = KeyVerificationDataLoadingCoordinator(session: session, verificationKind: verificationKind, incomingKeyVerificationRequest: keyVerificationRequest)
        coordinator.delegate = self
        coordinator.start()
        
        return coordinator
    }
    
    private func createUserVerificationStartCoordinator(with roomMember: MXRoomMember) -> UserVerificationStartCoordinator {
        let coordinator = UserVerificationStartCoordinator(session: session, roomMember: roomMember)
        coordinator.delegate = self
        coordinator.start()
        
        return coordinator
    }

    private func showStart(otherUser: MXUser, otherDevice: MXDeviceInfo) {
        let coordinator = DeviceVerificationStartCoordinator(session: session, otherUser: otherUser, otherDevice: otherDevice)
        coordinator.delegate = self
        coordinator.start()

        add(childCoordinator: coordinator)
        navigationRouter.setRootModule(coordinator) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }

    private func showIncoming(otherUser: MXUser, transaction: MXIncomingSASTransaction) {
        let coordinator = DeviceVerificationIncomingCoordinator(session: session, otherUser: otherUser, transaction: transaction)
        coordinator.delegate = self
        coordinator.start()

        add(childCoordinator: coordinator)
        navigationRouter.setRootModule(coordinator) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }

    private func showVerifyBySAS(transaction: MXSASTransaction, animated: Bool) {
        let coordinator = KeyVerificationVerifyBySASCoordinator(session: session, transaction: transaction, verificationKind: verificationKind)
        coordinator.delegate = self
        coordinator.start()

        add(childCoordinator: coordinator)
        navigationRouter.push(coordinator, animated: animated) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    private func showVerifyByScanning(keyVerificationRequest: MXKeyVerificationRequest, animated: Bool) {
        let coordinator = KeyVerificationVerifyByScanningCoordinator(session: session, verificationKind: verificationKind, keyVerificationRequest: keyVerificationRequest)
        coordinator.delegate = self
        coordinator.start()
        
        add(childCoordinator: coordinator)
        navigationRouter.push(coordinator, animated: animated) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    private func showScanConfirmation(for transaction: MXQRCodeTransaction, codeScanning: KeyVerificationScanning, animated: Bool) {
        let coordinator = KeyVerificationScanConfirmationCoordinator(session: session, transaction: transaction, codeScanning: codeScanning, verificationKind: verificationKind)
        coordinator.delegate = self
        coordinator.start()
        
        add(childCoordinator: coordinator)
        navigationRouter.push(coordinator, animated: animated) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }

    private func showVerified(animated: Bool) {
        let viewController = KeyVerificationVerifiedViewController.instantiate(with: verificationKind)
        viewController.delegate = self
        navigationRouter.setRootModule(viewController)
    }
}

// MARK: - KeyVerificationDataLoadingCoordinatorDelegate

extension KeyVerificationCoordinator: KeyVerificationDataLoadingCoordinatorDelegate {
    func keyVerificationDataLoadingCoordinator(_ coordinator: KeyVerificationDataLoadingCoordinatorType, didAcceptKeyVerificationRequest keyVerificationRequest: MXKeyVerificationRequest) {
        showVerifyByScanning(keyVerificationRequest: keyVerificationRequest, animated: true)
    }
    
    func keyVerificationDataLoadingCoordinator(_ coordinator: KeyVerificationDataLoadingCoordinatorType, didLoadUser user: MXUser, device: MXDeviceInfo) {
        if case .incomingSASTransaction(let incomingTransaction) = verificationFlow {
            self.showIncoming(otherUser: user, transaction: incomingTransaction)
        } else {
            showStart(otherUser: user, otherDevice: device)
        }
    }
    
    func keyVerificationDataLoadingCoordinator(_ coordinator: KeyVerificationDataLoadingCoordinatorType, didAcceptKeyVerificationRequestWithTransaction transaction: MXKeyVerificationTransaction) {
        if let sasTransaction = transaction as? MXSASTransaction {
            showVerifyBySAS(transaction: sasTransaction, animated: true)
        } else {
            MXLog.debug("[KeyVerificationCoordinator] Transaction \(transaction) is not supported")
            didCancel()
        }
    }

    func keyVerificationDataLoadingCoordinatorDidCancel(_ coordinator: KeyVerificationDataLoadingCoordinatorType) {
        didCancel()
    }
}

// MARK: - DeviceVerificationStartCoordinatorDelegate

extension KeyVerificationCoordinator: DeviceVerificationStartCoordinatorDelegate {
    func deviceVerificationStartCoordinator(_ coordinator: DeviceVerificationStartCoordinatorType, didCompleteWithOutgoingTransaction transaction: MXSASTransaction) {
        showVerifyBySAS(transaction: transaction, animated: true)
    }

    func deviceVerificationStartCoordinator(_ coordinator: DeviceVerificationStartCoordinatorType, didTransactionCancelled transaction: MXSASTransaction) {
        didCancel()
    }

    func deviceVerificationStartCoordinatorDidCancel(_ coordinator: DeviceVerificationStartCoordinatorType) {
        didCancel()
    }
}

// MARK: - DeviceVerificationIncomingCoordinatorDelegate

extension KeyVerificationCoordinator: DeviceVerificationIncomingCoordinatorDelegate {
    func deviceVerificationIncomingCoordinator(_ coordinator: DeviceVerificationIncomingCoordinatorType, didAcceptTransaction transaction: MXSASTransaction) {
        showVerifyBySAS(transaction: transaction, animated: true)
    }

    func deviceVerificationIncomingCoordinatorDidCancel(_ coordinator: DeviceVerificationIncomingCoordinatorType) {
        didCancel()
    }
}

// MARK: - KeyVerificationVerifyBySASCoordinatorDelegate

extension KeyVerificationCoordinator: KeyVerificationVerifyBySASCoordinatorDelegate {
    func keyVerificationVerifyBySASCoordinatorDidComplete(_ coordinator: KeyVerificationVerifyBySASCoordinatorType) {
        showVerified(animated: true)
    }

    func keyVerificationVerifyBySASCoordinatorDidCancel(_ coordinator: KeyVerificationVerifyBySASCoordinatorType) {
        didCancel()
    }
}

// MARK: - KeyVerificationVerifiedViewControllerDelegate

extension KeyVerificationCoordinator: KeyVerificationVerifiedViewControllerDelegate {
    func keyVerificationVerifiedViewControllerDidTapSetupAction(_ viewController: KeyVerificationVerifiedViewController) {
        didComplete()
    }

    func keyVerificationVerifiedViewControllerDidCancel(_ viewController: KeyVerificationVerifiedViewController) {
        didCancel()
    }
}

// MARK: - UserVerificationStartCoordinatorDelegate

extension KeyVerificationCoordinator: UserVerificationStartCoordinatorDelegate {
    func userVerificationStartCoordinator(_ coordinator: UserVerificationStartCoordinatorType, otherDidAcceptRequest request: MXKeyVerificationRequest) {
        showVerifyByScanning(keyVerificationRequest: request, animated: true)
    }
    
    func userVerificationStartCoordinator(_ coordinator: UserVerificationStartCoordinatorType, didCompleteWithOutgoingTransaction transaction: MXSASTransaction) {
        showVerifyBySAS(transaction: transaction, animated: true)
    }
    
    func userVerificationStartCoordinator(_ coordinator: UserVerificationStartCoordinatorType, didTransactionCancelled transaction: MXSASTransaction) {
        didCancel()
    }
    
    func userVerificationStartCoordinatorDidCancel(_ coordinator: UserVerificationStartCoordinatorType) {
        didCancel()
    }
}

// MARK: - KeyVerificationVerifyByScanningCoordinatorDelegate

extension KeyVerificationCoordinator: KeyVerificationVerifyByScanningCoordinatorDelegate {
    func keyVerificationVerifyByScanningCoordinatorDidCancel(_ coordinator: KeyVerificationVerifyByScanningCoordinatorType) {
        didCancel()
    }
    
    func keyVerificationVerifyByScanningCoordinator(_ coordinator: KeyVerificationVerifyByScanningCoordinatorType, didScanOtherQRCodeData qrCodeData: MXQRCodeData, withTransaction transaction: MXQRCodeTransaction) {
        showScanConfirmation(for: transaction, codeScanning: .scannedOtherQRCode(qrCodeData), animated: true)
    }
    
    func keyVerificationVerifyByScanningCoordinator(_ coordinator: KeyVerificationVerifyByScanningCoordinatorType, qrCodeDidScannedByOtherWithTransaction transaction: MXQRCodeTransaction) {
        showScanConfirmation(for: transaction, codeScanning: .myQRCodeScanned, animated: true)
    }
    
    func keyVerificationVerifyByScanningCoordinator(_ coordinator: KeyVerificationVerifyByScanningCoordinatorType, didCompleteWithSASTransaction transaction: MXSASTransaction) {
        showVerifyBySAS(transaction: transaction, animated: true)
    }
}

// MARK: - KeyVerificationSelfVerifyStartCoordinatorDelegate

extension KeyVerificationCoordinator: KeyVerificationSelfVerifyStartCoordinatorDelegate {
    func keyVerificationSelfVerifyStartCoordinator(_ coordinator: KeyVerificationSelfVerifyStartCoordinatorType, otherDidAcceptRequest request: MXKeyVerificationRequest) {
        showVerifyByScanning(keyVerificationRequest: request, animated: true)
    }
    
    func keyVerificationSelfVerifyStartCoordinatorDidCancel(_ coordinator: KeyVerificationSelfVerifyStartCoordinatorType) {
        didCancel()
    }
}

// MARK: - KeyVerificationSelfVerifyWaitCoordinatorDelegate

extension KeyVerificationCoordinator: KeyVerificationSelfVerifyWaitCoordinatorDelegate {
    func keyVerificationSelfVerifyWaitCoordinator(_ coordinator: KeyVerificationSelfVerifyWaitCoordinatorType, didAcceptKeyVerificationRequest keyVerificationRequest: MXKeyVerificationRequest) {
        showVerifyByScanning(keyVerificationRequest: keyVerificationRequest, animated: true)
    }
    
    func keyVerificationSelfVerifyWaitCoordinator(_ coordinator: KeyVerificationSelfVerifyWaitCoordinatorType, didAcceptIncomingSASTransaction incomingSASTransaction: MXIncomingSASTransaction) {
        showVerifyBySAS(transaction: incomingSASTransaction, animated: true)
    }
    
    func keyVerificationSelfVerifyWaitCoordinatorDidCancel(_ coordinator: KeyVerificationSelfVerifyWaitCoordinatorType) {
        didCancel()
    }
    
    func keyVerificationSelfVerifyWaitCoordinator(_ coordinator: KeyVerificationSelfVerifyWaitCoordinatorType, wantsToRecoverSecretsWith secretsRecoveryMode: SecretsRecoveryMode) {
        showSecretsRecovery(with: secretsRecoveryMode)
    }
}

// MARK: - KeyVerificationScanConfirmationCoordinatorDelegate

extension KeyVerificationCoordinator: KeyVerificationScanConfirmationCoordinatorDelegate {
    func keyVerificationScanConfirmationCoordinatorDidComplete(_ coordinator: KeyVerificationScanConfirmationCoordinatorType) {
        showVerified(animated: true)
    }
    
    func keyVerificationScanConfirmationCoordinatorDidCancel(_ coordinator: KeyVerificationScanConfirmationCoordinatorType) {
        didCancel()
    }
}

// MARK: - SecretsRecoveryCoordinatorDelegate

extension KeyVerificationCoordinator: SecretsRecoveryCoordinatorDelegate {
    func secretsRecoveryCoordinatorDidRecover(_ coordinator: SecretsRecoveryCoordinatorType) {
        remove(childCoordinator: coordinator)
        showVerified(animated: true)
    }
    
    func secretsRecoveryCoordinatorDidCancel(_ coordinator: SecretsRecoveryCoordinatorType) {
        remove(childCoordinator: coordinator)
        didCancel()
    }
}
