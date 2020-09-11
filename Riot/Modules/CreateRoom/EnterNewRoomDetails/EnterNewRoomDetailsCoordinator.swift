// File created from ScreenTemplate
// $ createScreen.sh CreateRoom/EnterNewRoomDetails EnterNewRoomDetails
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

final class EnterNewRoomDetailsCoordinator: EnterNewRoomDetailsCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var enterNewRoomDetailsViewModel: EnterNewRoomDetailsViewModelType
    private let enterNewRoomDetailsViewController: EnterNewRoomDetailsViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: EnterNewRoomDetailsCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        
        let enterNewRoomDetailsViewModel = EnterNewRoomDetailsViewModel(session: self.session)
        let enterNewRoomDetailsViewController = EnterNewRoomDetailsViewController.instantiate(with: enterNewRoomDetailsViewModel)
        self.enterNewRoomDetailsViewModel = enterNewRoomDetailsViewModel
        self.enterNewRoomDetailsViewController = enterNewRoomDetailsViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.enterNewRoomDetailsViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.enterNewRoomDetailsViewController
    }
}

// MARK: - EnterNewRoomDetailsViewModelCoordinatorDelegate
extension EnterNewRoomDetailsCoordinator: EnterNewRoomDetailsViewModelCoordinatorDelegate {
    
    func enterNewRoomDetailsViewModel(_ viewModel: EnterNewRoomDetailsViewModelType, didCreateNewRoom room: MXRoom) {
        self.delegate?.enterNewRoomDetailsCoordinator(self, didCreateNewRoom: room)
    }
    
    func enterNewRoomDetailsViewModelDidCancel(_ viewModel: EnterNewRoomDetailsViewModelType) {
        self.delegate?.enterNewRoomDetailsCoordinatorDidCancel(self)
    }
}
