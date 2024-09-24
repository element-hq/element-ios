// File created from ScreenTemplate
// $ createScreen.sh SetPinCode/EnterPinCode EnterPinCode
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol EnterPinCodeViewModelViewDelegate: AnyObject {
    func enterPinCodeViewModel(_ viewModel: EnterPinCodeViewModelType, didUpdateViewState viewSate: EnterPinCodeViewState)
    func enterPinCodeViewModel(_ viewModel: EnterPinCodeViewModelType, didUpdatePlaceholdersCount count: Int)
    func enterPinCodeViewModel(_ viewModel: EnterPinCodeViewModelType, didUpdateCancelButtonHidden isHidden: Bool)
}

protocol EnterPinCodeViewModelCoordinatorDelegate: AnyObject {
    func enterPinCodeViewModelDidComplete(_ viewModel: EnterPinCodeViewModelType)
    func enterPinCodeViewModelDidCompleteWithReset(_ viewModel: EnterPinCodeViewModelType, dueToTooManyErrors: Bool)
    func enterPinCodeViewModel(_ viewModel: EnterPinCodeViewModelType, didCompleteWithPin pin: String)
    func enterPinCodeViewModelDidCancel(_ viewModel: EnterPinCodeViewModelType)
}

/// Protocol describing the view model used by `EnterPinCodeViewController`
protocol EnterPinCodeViewModelType {        
        
    var viewDelegate: EnterPinCodeViewModelViewDelegate? { get set }
    var coordinatorDelegate: EnterPinCodeViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: EnterPinCodeViewAction)
}
