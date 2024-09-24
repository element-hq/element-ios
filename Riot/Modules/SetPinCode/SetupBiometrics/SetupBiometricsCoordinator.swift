// File created from ScreenTemplate
// $ createScreen.sh SetPinCode/SetupBiometrics SetupBiometrics
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
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
