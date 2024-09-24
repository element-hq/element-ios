// File created from ScreenTemplate
// $ createScreen.sh ReactionHistory ReactionHistory
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
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
