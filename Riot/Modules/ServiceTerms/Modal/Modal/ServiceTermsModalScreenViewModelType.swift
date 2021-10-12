// File created from ScreenTemplate
// $ createScreen.sh Modal/Show ServiceTermsModalScreen
/*
 Copyright 2019 New Vector Ltd
 
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

protocol ServiceTermsModalScreenViewModelViewDelegate: AnyObject {
    func serviceTermsModalScreenViewModel(_ viewModel: ServiceTermsModalScreenViewModelType, didUpdateViewState viewSate: ServiceTermsModalScreenViewState)
}

protocol ServiceTermsModalScreenViewModelCoordinatorDelegate: AnyObject {
    func serviceTermsModalScreenViewModel(_ coordinator: ServiceTermsModalScreenViewModelType, displayPolicy policy: MXLoginPolicyData)
    func serviceTermsModalScreenViewModelDidAccept(_ viewModel: ServiceTermsModalScreenViewModelType)
    func serviceTermsModalScreenViewModelDidDecline(_ viewModel: ServiceTermsModalScreenViewModelType)
}

/// Protocol describing the view model used by `ServiceTermsModalScreenViewController`
protocol ServiceTermsModalScreenViewModelType {

    var serviceUrl: String { get }
    var serviceType: MXServiceType { get }
    var policies: [MXLoginPolicyData]? { get set }
    var alreadyAcceptedPoliciesUrls: [String] { get set }
        
    var viewDelegate: ServiceTermsModalScreenViewModelViewDelegate? { get set }
    var coordinatorDelegate: ServiceTermsModalScreenViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: ServiceTermsModalScreenViewAction)
}
