// File created from FlowTemplate
// $ createRootCoordinator.sh CrossSigning CrossSigningSetup
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// CrossSigningSetupCoordinatorBridgePresenter enables to start CrossSigningSetupCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// It breaks the Coordinator abstraction and it has been introduced for Objective-C compatibility (mainly for integration in legacy view controllers).
/// Each bridge should be removed once the underlying Coordinator has been integrated by another Coordinator.
@objcMembers
final class CrossSigningSetupCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var coordinator: CrossSigningSetupCoordinator?
    
    private var didComplete: (() -> Void)?
    private var didCancel: (() -> Void)?
    private var didFail: ((Error) -> Void)?        
        
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        super.init()
    }
    
    // MARK: - Public
    
    func present(with title: String,
                 message: String,
                 from viewController: UIViewController,
                 animated: Bool,
                 success: @escaping () -> Void,
                 cancel: @escaping () -> Void,
                 failure: @escaping (Error) -> Void) {
        
        self.didComplete = success
        self.didCancel = cancel
        self.didFail = failure
        
        let parameters = CrossSigningSetupCoordinatorParameters(session: self.session, presenter: viewController, title: title, message: message)
        
        let crossSigningSetupCoordinator = CrossSigningSetupCoordinator(parameters: parameters)
        crossSigningSetupCoordinator.delegate = self
        crossSigningSetupCoordinator.start()
        
        self.coordinator = crossSigningSetupCoordinator
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        
        self.resetCompletions()
        
        guard let coordinator = self.coordinator else {
            return
        }
        coordinator.toPresentable().dismiss(animated: animated) {
            self.coordinator = nil

            if let completion = completion {
                completion()
            }
        }
    }
    
    private func resetCompletions() {
        self.didComplete = nil
        self.didCancel = nil
        self.didFail = nil
    }
}

// MARK: - CrossSigningSetupCoordinatorDelegate
extension CrossSigningSetupCoordinatorBridgePresenter: CrossSigningSetupCoordinatorDelegate {
    func crossSigningSetupCoordinatorDidComplete(_ coordinator: CrossSigningSetupCoordinatorType) {
        self.didComplete?()
    }
    
    func crossSigningSetupCoordinatorDidCancel(_ coordinator: CrossSigningSetupCoordinatorType) {
        self.didCancel?()
    }
    
    func crossSigningSetupCoordinator(_ coordinator: CrossSigningSetupCoordinatorType, didFailWithError error: Error) {
        self.didFail?(error)
    }
}
