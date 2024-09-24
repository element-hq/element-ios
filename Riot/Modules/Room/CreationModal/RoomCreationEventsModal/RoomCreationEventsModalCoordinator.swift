// File created from ScreenTemplate
// $ createScreen.sh Modal2/RoomCreation RoomCreationEventsModal
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
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
