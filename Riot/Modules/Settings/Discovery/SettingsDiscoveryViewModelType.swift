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

protocol SettingsDiscoveryViewModelViewDelegate: AnyObject {
    func settingsDiscoveryViewModel(_ viewModel: SettingsDiscoveryViewModelType, didUpdateViewState viewState: SettingsDiscoveryViewState)
}

@objc protocol SettingsDiscoveryViewModelCoordinatorDelegate: AnyObject {
    func settingsDiscoveryViewModel(_ viewModel: SettingsDiscoveryViewModel, didSelectThreePidWith medium: String, and address: String)
    func settingsDiscoveryViewModelDidTapAcceptIdentityServerTerms(_ viewModel: SettingsDiscoveryViewModel)
}

protocol SettingsDiscoveryViewModelType {
    
    var viewDelegate: SettingsDiscoveryViewModelViewDelegate? { get set }
    
    var coordinatorDelegate: SettingsDiscoveryViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: SettingsDiscoveryViewAction)
}
