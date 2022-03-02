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

protocol ThreadListViewModelViewDelegate: AnyObject {
    func threadListViewModel(_ viewModel: ThreadListViewModelProtocol, didUpdateViewState viewSate: ThreadListViewState)
}

protocol ThreadListViewModelCoordinatorDelegate: AnyObject {
    func threadListViewModelDidLoadThreads(_ viewModel: ThreadListViewModelProtocol)
    func threadListViewModelDidSelectThread(_ viewModel: ThreadListViewModelProtocol, thread: MXThreadProtocol)
    func threadListViewModelDidSelectThreadViewInRoom(_ viewModel: ThreadListViewModelProtocol, thread: MXThreadProtocol)
    func threadListViewModelDidCancel(_ viewModel: ThreadListViewModelProtocol)
}

/// Protocol describing the view model used by `ThreadListViewController`
protocol ThreadListViewModelProtocol {        
        
    var viewDelegate: ThreadListViewModelViewDelegate? { get set }
    var coordinatorDelegate: ThreadListViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: ThreadListViewAction)
    
    var viewState: ThreadListViewState { get }
    
    var titleModel: ThreadRoomTitleModel { get }
    var selectedFilterType: ThreadListFilterType { get }
    var numberOfThreads: Int { get }
    func threadModel(at index: Int) -> ThreadModel?
}

enum ThreadListFilterType {
    case all
    case myThreads
    
    var title: String {
        switch self {
        case .all:
            return VectorL10n.threadsActionAllThreads
        case .myThreads:
            return VectorL10n.threadsActionMyThreads
        }
    }
}
