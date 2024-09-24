// File created from ScreenTemplate
// $ createScreen.sh Room2/RoomInfo RoomInfoList
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit

final class RoomInfoListCoordinator: RoomInfoListCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let room: MXRoom
    private var roomInfoListViewModel: RoomInfoListViewModelType
    private let roomInfoListViewController: RoomInfoListViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: RoomInfoListCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, room: MXRoom) {
        self.session = session
        self.room = room
        
        let roomInfoListViewModel = RoomInfoListViewModel(session: self.session, room: room)
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
    
    func roomInfoListViewModel(_ viewModel: RoomInfoListViewModelType, wantsToNavigateTo target: RoomInfoListTarget) {
        self.delegate?.roomInfoListCoordinator(self, wantsToNavigateTo: target)
    }
    
    func roomInfoListViewModelDidCancel(_ viewModel: RoomInfoListViewModelType) {
        self.delegate?.roomInfoListCoordinatorDidCancel(self)
    }
    
    func roomInfoListViewModelDidLeaveRoom(_ viewModel: RoomInfoListViewModelType) {
        self.delegate?.roomInfoListCoordinatorDidLeaveRoom(self)
    }

    func roomInfoListViewModelDidRequestReportRoom(_ viewModel: RoomInfoListViewModelType) {
        self.delegate?.roomInfoListCoordinatorDidRequestReportRoom(self)
    }
}
