// File created from ScreenTemplate
// $ createScreen.sh Rooms2/ShowDirectory ShowDirectory
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
import UIKit

final class ShowDirectoryCoordinator: ShowDirectoryCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var showDirectoryViewModel: ShowDirectoryViewModelType
    private let showDirectoryViewController: ShowDirectoryViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ShowDirectoryCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        
        let showDirectoryViewModel = ShowDirectoryViewModel(session: self.session)
        let showDirectoryViewController = ShowDirectoryViewController.instantiate(with: showDirectoryViewModel)
        self.showDirectoryViewModel = showDirectoryViewModel
        self.showDirectoryViewController = showDirectoryViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.showDirectoryViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.showDirectoryViewController
    }
}

// MARK: - ShowDirectoryViewModelCoordinatorDelegate
extension ShowDirectoryCoordinator: ShowDirectoryViewModelCoordinatorDelegate {
    
    func showDirectoryViewModel(_ viewModel: ShowDirectoryViewModelType, didCompleteWithUserDisplayName userDisplayName: String?) {
        self.delegate?.showDirectoryCoordinator(self, didCompleteWithUserDisplayName: userDisplayName)
    }
    
    func showDirectoryViewModelDidCancel(_ viewModel: ShowDirectoryViewModelType) {
        self.delegate?.showDirectoryCoordinatorDidCancel(self)
    }
}
