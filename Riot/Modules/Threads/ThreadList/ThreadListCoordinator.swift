// File created from ScreenTemplate
// $ createScreen.sh Threads/ThreadList ThreadList
/*
 Copyright 2021 New Vector Ltd
 
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
