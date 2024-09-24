// File created from ScreenTemplate
// $ createScreen.sh SetPinCode/EnterPinCode EnterPinCode
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit

final class EnterPinCodeCoordinator: EnterPinCodeCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession?
    private var enterPinCodeViewModel: EnterPinCodeViewModelType
    private let enterPinCodeViewController: EnterPinCodeViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: EnterPinCodeCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession?, viewMode: SetPinCoordinatorViewMode, pinCodePreferences: PinCodePreferences = .shared) {
        self.session = session
        
        let enterPinCodeViewModel = EnterPinCodeViewModel(session: self.session, viewMode: viewMode, pinCodePreferences: pinCodePreferences)
        let enterPinCodeViewController = EnterPinCodeViewController.instantiate(with: enterPinCodeViewModel)
        self.enterPinCodeViewModel = enterPinCodeViewModel
        self.enterPinCodeViewController = enterPinCodeViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.enterPinCodeViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.enterPinCodeViewController
    }
}

// MARK: - EnterPinCodeViewModelCoordinatorDelegate
extension EnterPinCodeCoordinator: EnterPinCodeViewModelCoordinatorDelegate {
    
    func enterPinCodeViewModelDidComplete(_ viewModel: EnterPinCodeViewModelType) {
        self.delegate?.enterPinCodeCoordinatorDidComplete(self)
    }
    
    func enterPinCodeViewModelDidCompleteWithReset(_ viewModel: EnterPinCodeViewModelType, dueToTooManyErrors: Bool) {
        self.delegate?.enterPinCodeCoordinatorDidCompleteWithReset(self, dueToTooManyErrors: dueToTooManyErrors)
    }
    
    func enterPinCodeViewModel(_ viewModel: EnterPinCodeViewModelType, didCompleteWithPin pin: String) {
        self.delegate?.enterPinCodeCoordinator(self, didCompleteWithPin: pin)
    }
    
    func enterPinCodeViewModelDidCancel(_ viewModel: EnterPinCodeViewModelType) {
        self.delegate?.enterPinCodeCoordinatorDidCancel(self)
    }
}
