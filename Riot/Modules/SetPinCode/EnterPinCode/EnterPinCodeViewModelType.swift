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
