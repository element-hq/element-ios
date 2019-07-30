// File created from ScreenTemplate
// $ createScreen.sh ReactionHistory ReactionHistory
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

final class ReactionHistoryCoordinator: ReactionHistoryCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let roomId: String
    private let eventId: String
    private let router: NavigationRouter
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ReactionHistoryCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, roomId: String, eventId: String) {
        self.session = session
        self.roomId = roomId
        self.eventId = eventId
        self.router = NavigationRouter(navigationController: RiotNavigationController())
    }
    
    // MARK: - Public methods
    
    func start() {
        let reactionHistoryViewModel = ReactionHistoryViewModel(session: session, roomId: roomId, eventId: eventId)
        let reactionHistoryViewController = ReactionHistoryViewController.instantiate(with: reactionHistoryViewModel)
        reactionHistoryViewModel.coordinatorDelegate = self
        self.router.setRootModule(reactionHistoryViewController)
    }
    
    func toPresentable() -> UIViewController {
        return self.router.toPresentable()
    }
}

// MARK: - ReactionHistoryViewModelCoordinatorDelegate
extension ReactionHistoryCoordinator: ReactionHistoryViewModelCoordinatorDelegate {
    func reactionHistoryViewModelDidClose(_ viewModel: ReactionHistoryViewModelType) {
        self.delegate?.reactionHistoryCoordinatorDidClose(self)
    }
}
