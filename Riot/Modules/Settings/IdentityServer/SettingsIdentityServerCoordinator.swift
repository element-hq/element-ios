// File created from FlowTemplate
// $ createRootCoordinator.sh Test SettingsIdentityServer
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

import UIKit

@objcMembers
final class SettingsIdentityServerCoordinator: SettingsIdentityServerCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let settingsIdentityServerViewController: SettingsIdentityServerViewController
    
    // MARK: Public
    
    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        
        let settingsIdentityServerViewModel = SettingsIdentityServerViewModel(session: self.session)
        let settingsIdentityServerViewController = SettingsIdentityServerViewController.instantiate(with: settingsIdentityServerViewModel)
        self.settingsIdentityServerViewController = settingsIdentityServerViewController
    }
    
    // MARK: - Public methods
    
    func start() {
    }
    
    func toPresentable() -> UIViewController {
        return self.settingsIdentityServerViewController
    }
}
