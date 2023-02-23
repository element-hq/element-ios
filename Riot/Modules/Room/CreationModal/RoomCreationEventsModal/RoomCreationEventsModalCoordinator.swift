// File created from ScreenTemplate
// $ createScreen.sh Modal2/RoomCreation RoomCreationEventsModal
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

final class RoomCreationEventsModalCoordinator: RoomCreationEventsModalCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var roomCreationEventsModalViewModel: RoomCreationEventsModalViewModelType
    private let roomCreationEventsModalViewController: RoomCreationEventsModalViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: RoomCreationEventsModalCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, roomState: MXRoomState) {
        self.session = session
        
        let roomCreationEventsModalViewModel = RoomCreationEventsModalViewModel(session: self.session, roomState: roomState)
        let roomCreationEventsModalViewController = RoomCreationEventsModalViewController.instantiate(with: roomCreationEventsModalViewModel)
        self.roomCreationEventsModalViewModel = roomCreationEventsModalViewModel
        self.roomCreationEventsModalViewController = roomCreationEventsModalViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.roomCreationEventsModalViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.roomCreationEventsModalViewController
    }
    
    func toSlidingModalPresentable() -> UIViewController & SlidingModalPresentable {
        return self.roomCreationEventsModalViewController
    }
}

// MARK: - RoomCreationEventsModalViewModelCoordinatorDelegate
extension RoomCreationEventsModalCoordinator: RoomCreationEventsModalViewModelCoordinatorDelegate {
    
    func roomCreationEventsModalViewModelDidTapClose(_ viewModel: RoomCreationEventsModalViewModelType) {
        self.delegate?.roomCreationEventsModalCoordinatorDidTapClose(self)
    }
    
}
