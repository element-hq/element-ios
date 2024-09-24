// File created from ScreenTemplate
// $ createScreen.sh UserVerification UserVerificationSessionsStatus
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit

final class UserVerificationSessionsStatusCoordinator: UserVerificationSessionsStatusCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var userVerificationSessionsStatusViewModel: UserVerificationSessionsStatusViewModelType
    private let userVerificationSessionsStatusViewController: UserVerificationSessionsStatusViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: UserVerificationSessionsStatusCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, userId: String) {
        self.session = session
        
        let userVerificationSessionsStatusViewModel = UserVerificationSessionsStatusViewModel(session: self.session, userId: userId)
        let userVerificationSessionsStatusViewController = UserVerificationSessionsStatusViewController.instantiate(with: userVerificationSessionsStatusViewModel)
        self.userVerificationSessionsStatusViewModel = userVerificationSessionsStatusViewModel
        self.userVerificationSessionsStatusViewController = userVerificationSessionsStatusViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.userVerificationSessionsStatusViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.userVerificationSessionsStatusViewController
    }
}

// MARK: - UserVerificationSessionsStatusViewModelCoordinatorDelegate
extension UserVerificationSessionsStatusCoordinator: UserVerificationSessionsStatusViewModelCoordinatorDelegate {
    func userVerificationSessionsStatusViewModel(_ viewModel: UserVerificationSessionsStatusViewModelType, didSelectDeviceWithId deviceId: String, for userId: String) {
        self.delegate?.userVerificationSessionsStatusCoordinator(self, didSelectDeviceWithId: deviceId, for: userId)
    }
    
    func userVerificationSessionsStatusViewModelDidClose(_ viewModel: UserVerificationSessionsStatusViewModelType) {
        self.delegate?.userVerificationSessionsStatusCoordinatorDidClose(self)
    }
}
