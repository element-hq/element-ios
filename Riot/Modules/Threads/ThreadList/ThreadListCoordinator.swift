// File created from ScreenTemplate
// $ createScreen.sh Threads/ThreadList ThreadList
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit

final class ThreadListCoordinator: ThreadListCoordinatorProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: ThreadListCoordinatorParameters
    private var threadListViewModel: ThreadListViewModelProtocol
    private let threadListViewController: ThreadListViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ThreadListCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(parameters: ThreadListCoordinatorParameters) {
        self.parameters = parameters
        let threadListViewModel = ThreadListViewModel(session: self.parameters.session,
                                                      roomId: self.parameters.roomId)
        let threadListViewController = ThreadListViewController.instantiate(with: threadListViewModel)
        self.threadListViewModel = threadListViewModel
        self.threadListViewController = threadListViewController
    }
    
    // MARK: - Public
    
    func start() {            
        self.threadListViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.threadListViewController
    }
}

// MARK: - ThreadListViewModelCoordinatorDelegate
extension ThreadListCoordinator: ThreadListViewModelCoordinatorDelegate {
    
    func threadListViewModelDidLoadThreads(_ viewModel: ThreadListViewModelProtocol) {
        self.delegate?.threadListCoordinatorDidLoadThreads(self)
    }
    
    func threadListViewModelDidSelectThread(_ viewModel: ThreadListViewModelProtocol, thread: MXThreadProtocol) {
        self.delegate?.threadListCoordinatorDidSelectThread(self, thread: thread)
    }
    
    func threadListViewModelDidSelectThreadViewInRoom(_ viewModel: ThreadListViewModelProtocol, thread: MXThreadProtocol) {
        self.delegate?.threadListCoordinatorDidSelectRoom(self, roomId: thread.roomId, eventId: thread.id)
    }
    
    func threadListViewModelDidCancel(_ viewModel: ThreadListViewModelProtocol) {
        self.delegate?.threadListCoordinatorDidCancel(self)
    }
}
