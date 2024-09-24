// File created from ScreenTemplate
// $ createScreen.sh Start UserVerificationStart
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit

final class UserVerificationStartCoordinator: UserVerificationStartCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let roomMember: MXRoomMember
    
    private var userVerificationStartViewModel: UserVerificationStartViewModelType
    private let userVerificationStartViewController: UserVerificationStartViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: UserVerificationStartCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, roomMember: MXRoomMember) {
        self.session = session
        self.roomMember = roomMember
        
        let userVerificationStartViewModel = UserVerificationStartViewModel(session: self.session, roomMember: self.roomMember)
        let userVerificationStartViewController = UserVerificationStartViewController.instantiate(with: userVerificationStartViewModel)
        self.userVerificationStartViewModel = userVerificationStartViewModel
        self.userVerificationStartViewController = userVerificationStartViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.userVerificationStartViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.userVerificationStartViewController
    }
}

// MARK: - UserVerificationStartViewModelCoordinatorDelegate
extension UserVerificationStartCoordinator: UserVerificationStartViewModelCoordinatorDelegate {
    
    func userVerificationStartViewModel(_ viewModel: UserVerificationStartViewModelType, otherDidAcceptRequest request: MXKeyVerificationRequest) {
        self.delegate?.userVerificationStartCoordinator(self, otherDidAcceptRequest: request)
    }
    
    func userVerificationStartViewModelDidCancel(_ viewModel: UserVerificationStartViewModelType) {
        self.delegate?.userVerificationStartCoordinatorDidCancel(self)
    }
}
