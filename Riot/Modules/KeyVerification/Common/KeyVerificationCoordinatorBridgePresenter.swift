// File created from FlowTemplate
// $ createRootCoordinator.sh DeviceVerification DeviceVerification DeviceVerificationStart
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

@objc protocol KeyVerificationCoordinatorBridgePresenterDelegate {
    func keyVerificationCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: KeyVerificationCoordinatorBridgePresenter, otherUserId: String, otherDeviceId: String)
    func keyVerificationCoordinatorBridgePresenterDelegateDidCancel(_ coordinatorBridgePresenter: KeyVerificationCoordinatorBridgePresenter)
}

/// KeyVerificationCoordinatorBridgePresenter enables to start KeyVerificationCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class KeyVerificationCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    let session: MXSession
    private var coordinator: KeyVerificationCoordinator?
    
    // MARK: Public
    
    weak var delegate: KeyVerificationCoordinatorBridgePresenterDelegate?
    var cancellable: Bool = true
    
    var isPresenting: Bool {
        return self.coordinator != nil
    }
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        super.init()
    }
    
    // MARK: - Public
    
    // NOTE: Default value feature is not compatible with Objective-C.
    // func present(from viewController: UIViewController, animated: Bool) {
    //     self.present(from: viewController, animated: animated)
    // }
    
    func present(from viewController: UIViewController, otherUserId: String, otherDeviceId: String, animated: Bool) {
        
        MXLog.debug("[KeyVerificationCoordinatorBridgePresenter] Present from \(viewController)")
        
        let keyVerificationCoordinator = KeyVerificationCoordinator(session: self.session, flow: .verifyDevice(userId: otherUserId, deviceId: otherDeviceId), cancellable: self.cancellable)
        self.present(coordinator: keyVerificationCoordinator, from: viewController, animated: animated)
    }
    
    func present(from viewController: UIViewController, roomMember: MXRoomMember, animated: Bool) {
        
        MXLog.debug("[KeyVerificationCoordinatorBridgePresenter] Present from \(viewController)")
        
        let keyVerificationCoordinator = KeyVerificationCoordinator(session: self.session, flow: .verifyUser(roomMember), cancellable: self.cancellable)
        self.present(coordinator: keyVerificationCoordinator, from: viewController, animated: animated)
    }

    func present(from viewController: UIViewController, incomingTransaction: MXSASTransaction, animated: Bool) {
        
        MXLog.debug("[KeyVerificationCoordinatorBridgePresenter] Present incoming verification from \(viewController)")
        
        let keyVerificationCoordinator = KeyVerificationCoordinator(session: self.session, flow: .incomingSASTransaction(incomingTransaction), cancellable: self.cancellable)
        self.present(coordinator: keyVerificationCoordinator, from: viewController, animated: animated)
    }
    
    func present(from viewController: UIViewController, incomingKeyVerificationRequest: MXKeyVerificationRequest, animated: Bool) {
        
        MXLog.debug("[KeyVerificationCoordinatorBridgePresenter] Present incoming key verification request from \(viewController)")
        
        let keyVerificationCoordinator = KeyVerificationCoordinator(session: self.session, flow: .incomingRequest(incomingKeyVerificationRequest), cancellable: self.cancellable)
        self.present(coordinator: keyVerificationCoordinator, from: viewController, animated: animated)
    }
    
    func presentCompleteSecurity(from viewController: UIViewController, isNewSignIn: Bool, animated: Bool) {
        
        MXLog.debug("[KeyVerificationCoordinatorBridgePresenter] Present complete security from \(viewController)")
        
        let keyVerificationCoordinator = KeyVerificationCoordinator(session: self.session, flow: .completeSecurity(isNewSignIn), cancellable: self.cancellable)
        self.present(coordinator: keyVerificationCoordinator, from: viewController, animated: animated)
    }
    
    func pushCompleteSecurity(from navigationController: UINavigationController, isNewSignIn: Bool, animated: Bool) {
        
        MXLog.debug("[KeyVerificationCoordinatorBridgePresenter] Push complete security from \(navigationController)")
        
        let navigationRouter = NavigationRouterStore.shared.navigationRouter(for: navigationController)
        
        let keyVerificationCoordinator = KeyVerificationCoordinator(session: self.session, flow: .completeSecurity(isNewSignIn), navigationRouter: navigationRouter, cancellable: self.cancellable)
        keyVerificationCoordinator.delegate = self
        keyVerificationCoordinator.start() // Will trigger view controller push
        
        self.coordinator = keyVerificationCoordinator
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let coordinator = self.coordinator else {
            return
        }
        
        MXLog.debug("[KeyVerificationCoordinatorBridgePresenter] Dismiss")
        
        coordinator.toPresentable().dismiss(animated: animated) {
            self.coordinator = nil

            if let completion = completion {
                completion()
            }
        }
    }
    
    private func present(coordinator keyVerificationCoordinator: KeyVerificationCoordinator, from viewController: UIViewController, animated: Bool) {
        keyVerificationCoordinator.delegate = self
        let presentable = keyVerificationCoordinator.toPresentable()
        presentable.presentationController?.delegate = self
        viewController.present(presentable, animated: animated, completion: nil)
        keyVerificationCoordinator.start()
        
        self.coordinator = keyVerificationCoordinator
    }
}

// MARK: - KeyVerificationCoordinatorDelegate
extension KeyVerificationCoordinatorBridgePresenter: KeyVerificationCoordinatorDelegate {
    
    func keyVerificationCoordinatorDidComplete(_ coordinator: KeyVerificationCoordinatorType, otherUserId: String, otherDeviceId: String) {
        self.delegate?.keyVerificationCoordinatorBridgePresenterDelegateDidComplete(self, otherUserId: otherUserId, otherDeviceId: otherDeviceId)
    }
    
    func keyVerificationCoordinatorDidCancel(_ coordinator: KeyVerificationCoordinatorType) {
        self.delegate?.keyVerificationCoordinatorBridgePresenterDelegateDidCancel(self)
    }
}

extension KeyVerificationCoordinatorBridgePresenter: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if let coordinator = self.coordinator {
            keyVerificationCoordinatorDidCancel(coordinator)
        }
    }
    
}
