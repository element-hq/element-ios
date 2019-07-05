// File created from ScreenTemplate
// $ createScreen.sh Room/EditHistory EditHistory
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
import UIKit

final class EditHistoryCoordinator: EditHistoryCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private

    private var editHistoryViewModel: EditHistoryViewModelType
    private let editHistoryViewController: EditHistoryViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: EditHistoryCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession,
         formatter: MXKEventFormatter,
         event: MXEvent) {
        
        let editHistoryViewModel = EditHistoryViewModel(session: session, formatter: formatter, event: event)
        let editHistoryViewController = EditHistoryViewController.instantiate(with: editHistoryViewModel)
        self.editHistoryViewModel = editHistoryViewModel
        self.editHistoryViewController = editHistoryViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.editHistoryViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.editHistoryViewController
    }
}

// MARK: - EditHistoryViewModelCoordinatorDelegate
extension EditHistoryCoordinator: EditHistoryViewModelCoordinatorDelegate {

    func editHistoryViewModelDidClose(_ viewModel: EditHistoryViewModelType) {
        self.delegate?.editHistoryCoordinatorDidComplete(self)
    }
}
