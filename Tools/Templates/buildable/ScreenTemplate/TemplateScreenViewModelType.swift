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

protocol TemplateScreenViewModelViewDelegate: class {
    func templateScreenViewModel(_ viewModel: TemplateScreenViewModelType, didUpdateViewState viewSate: TemplateScreenViewState)
}

protocol TemplateScreenViewModelCoordinatorDelegate: class {
    func templateScreenViewModel(_ viewModel: TemplateScreenViewModelType, didCompleteWithUserDisplayName userDisplayName: String?)
    func templateScreenViewModelDidCancel(_ viewModel: TemplateScreenViewModelType)
}

/// Protocol describing the view model used by `TemplateScreenViewController`
protocol TemplateScreenViewModelType {        
        
    var viewDelegate: TemplateScreenViewModelViewDelegate? { get set }
    var coordinatorDelegate: TemplateScreenViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: TemplateScreenViewAction)
}
