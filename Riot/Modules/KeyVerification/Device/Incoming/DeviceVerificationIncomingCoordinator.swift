// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Incoming DeviceVerificationIncoming
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit

final class DeviceVerificationIncomingCoordinator: DeviceVerificationIncomingCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var deviceVerificationIncomingViewModel: DeviceVerificationIncomingViewModelType
    private let deviceVerificationIncomingViewController: DeviceVerificationIncomingViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: DeviceVerificationIncomingCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, otherUser: MXUser, transaction: MXSASTransaction) {
        self.session = session
        
        let deviceVerificationIncomingViewModel = DeviceVerificationIncomingViewModel(session: self.session, otherUser: otherUser, transaction: transaction)
        let deviceVerificationIncomingViewController = DeviceVerificationIncomingViewController.instantiate(with: deviceVerificationIncomingViewModel)
        self.deviceVerificationIncomingViewModel = deviceVerificationIncomingViewModel
        self.deviceVerificationIncomingViewController = deviceVerificationIncomingViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.deviceVerificationIncomingViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.deviceVerificationIncomingViewController
    }
}

// MARK: - DeviceVerificationIncomingViewModelCoordinatorDelegate
extension DeviceVerificationIncomingCoordinator: DeviceVerificationIncomingViewModelCoordinatorDelegate {
    
    func deviceVerificationIncomingViewModel(_ viewModel: DeviceVerificationIncomingViewModelType, didAcceptTransaction transaction: MXSASTransaction) {
        self.delegate?.deviceVerificationIncomingCoordinator(self, didAcceptTransaction: transaction)
    }
    
    func deviceVerificationIncomingViewModelDidCancel(_ viewModel: DeviceVerificationIncomingViewModelType) {
        self.delegate?.deviceVerificationIncomingCoordinatorDidCancel(self)
    }
}
