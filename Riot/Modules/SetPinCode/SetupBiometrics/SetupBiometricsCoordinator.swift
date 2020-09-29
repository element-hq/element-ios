// File created from ScreenTemplate
// $ createScreen.sh SetPinCode/SetupBiometrics SetupBiometrics
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

final class SetupBiometricsCoordinator: SetupBiometricsCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession?
    private var setupBiometricsViewModel: SetupBiometricsViewModelType
    private let setupBiometricsViewController: SetupBiometricsViewController
    private let viewMode: SetPinCoordinatorViewMode
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: SetupBiometricsCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession?, viewMode: SetPinCoordinatorViewMode, pinCodePreferences: PinCodePreferences = .shared) {
        self.session = session
        self.viewMode = viewMode
        
        let setupBiometricsViewModel = SetupBiometricsViewModel(session: self.session, viewMode: viewMode, pinCodePreferences: pinCodePreferences)
        let setupBiometricsViewController = SetupBiometricsViewController.instantiate(with: setupBiometricsViewModel)
        self.setupBiometricsViewModel = setupBiometricsViewModel
        self.setupBiometricsViewController = setupBiometricsViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.setupBiometricsViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.setupBiometricsViewController
    }
}

// MARK: - SetupBiometricsViewModelCoordinatorDelegate
extension SetupBiometricsCoordinator: SetupBiometricsViewModelCoordinatorDelegate {
    
    func setupBiometricsViewModelDidComplete(_ viewModel: SetupBiometricsViewModelType) {
        self.delegate?.setupBiometricsCoordinatorDidComplete(self)
    }
    
    func setupBiometricsViewModelDidCompleteWithReset(_ viewModel: SetupBiometricsViewModelType, dueToTooManyErrors: Bool) {
        self.delegate?.setupBiometricsCoordinatorDidCompleteWithReset(self, dueToTooManyErrors: dueToTooManyErrors)
    }
    
    func setupBiometricsViewModelDidCancel(_ viewModel: SetupBiometricsViewModelType) {
        self.delegate?.setupBiometricsCoordinatorDidCancel(self)
    }
}
