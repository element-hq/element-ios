// File created from ScreenTemplate
// $ createScreen.sh Room2/RoomInfo RoomInfoList
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

final class RoomInfoListCoordinator: RoomInfoListCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var roomInfoListViewModel: RoomInfoListViewModelType
    private let roomInfoListViewController: RoomInfoListViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: RoomInfoListCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        
        let roomInfoListViewModel = RoomInfoListViewModel(session: self.session)
        let roomInfoListViewController = RoomInfoListViewController.instantiate(with: roomInfoListViewModel)
        self.roomInfoListViewModel = roomInfoListViewModel
        self.roomInfoListViewController = roomInfoListViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.roomInfoListViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.roomInfoListViewController
    }
}

// MARK: - RoomInfoListViewModelCoordinatorDelegate
extension RoomInfoListCoordinator: RoomInfoListViewModelCoordinatorDelegate {
    
    func roomInfoListViewModel(_ viewModel: RoomInfoListViewModelType, didCompleteWithUserDisplayName userDisplayName: String?) {
        self.delegate?.roomInfoListCoordinator(self, didCompleteWithUserDisplayName: userDisplayName)
    }
    
    func roomInfoListViewModelDidCancel(_ viewModel: RoomInfoListViewModelType) {
        self.delegate?.roomInfoListCoordinatorDidCancel(self)
    }
}
