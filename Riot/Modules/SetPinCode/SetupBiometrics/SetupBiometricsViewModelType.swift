// File created from ScreenTemplate
// $ createScreen.sh SetPinCode/SetupBiometrics SetupBiometrics
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol SetupBiometricsViewModelViewDelegate: AnyObject {
    func setupBiometricsViewModel(_ viewModel: SetupBiometricsViewModelType, didUpdateViewState viewSate: SetupBiometricsViewState)
}

protocol SetupBiometricsViewModelCoordinatorDelegate: AnyObject {
    func setupBiometricsViewModelDidComplete(_ viewModel: SetupBiometricsViewModelType)
    func setupBiometricsViewModelDidCompleteWithReset(_ viewModel: SetupBiometricsViewModelType, dueToTooManyErrors: Bool)
    func setupBiometricsViewModelDidCancel(_ viewModel: SetupBiometricsViewModelType)
}

/// Protocol describing the view model used by `SetupBiometricsViewController`
protocol SetupBiometricsViewModelType {        
        
    var viewDelegate: SetupBiometricsViewModelViewDelegate? { get set }
    var coordinatorDelegate: SetupBiometricsViewModelCoordinatorDelegate? { get set }
    
    func localizedBiometricsName() -> String?
    func biometricsIcon() -> UIImage?
    func process(viewAction: SetupBiometricsViewAction)
}
