// File created from ScreenTemplate
// $ createScreen.sh Communities GroupDetails
/*
 Copyright 2021 New Vector Ltd
 
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

final class GroupDetailsCoordinator: GroupDetailsCoordinatorProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: GroupDetailsCoordinatorParameters
    private let groupDetailsViewController: GroupDetailsViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: GroupDetailsCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(parameters: GroupDetailsCoordinatorParameters) {
        self.parameters = parameters
        let groupDetailsViewController: GroupDetailsViewController = GroupDetailsViewController.instantiate()
        self.groupDetailsViewController = groupDetailsViewController
    }
    
    deinit {
        groupDetailsViewController.destroy()
    }
    
    // MARK: - Public
    
    func start() {
        self.groupDetailsViewController.setGroup(self.parameters.group, withMatrixSession: self.parameters.session)
    }
    
    func toPresentable() -> UIViewController {
        return self.groupDetailsViewController
    }
}
