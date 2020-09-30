// File created from ScreenTemplate
// $ createScreen.sh SetPinCode/EnterPinCode EnterPinCode
/*
 Copyright 2020 New Vector Ltd
 
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
