// File created from ScreenTemplate
// $ createScreen.sh Threads/ThreadList ThreadList
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
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
