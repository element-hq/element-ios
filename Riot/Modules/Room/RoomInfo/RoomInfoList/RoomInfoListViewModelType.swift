// File created from ScreenTemplate
// $ createScreen.sh Room2/RoomInfo RoomInfoList
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol RoomInfoListViewModelViewDelegate: AnyObject {
    func roomInfoListViewModel(_ viewModel: RoomInfoListViewModelType, didUpdateViewState viewSate: RoomInfoListViewState)
}

protocol RoomInfoListViewModelCoordinatorDelegate: AnyObject {
    func roomInfoListViewModelDidCancel(_ viewModel: RoomInfoListViewModelType)
    func roomInfoListViewModelDidLeaveRoom(_ viewModel: RoomInfoListViewModelType)
    func roomInfoListViewModel(_ viewModel: RoomInfoListViewModelType, wantsToNavigateTo target: RoomInfoListTarget)
    func roomInfoListViewModelDidRequestReportRoom(_ viewModel: RoomInfoListViewModelType)
}

/// Protocol describing the view model used by `RoomInfoListViewController`
protocol RoomInfoListViewModelType {        
        
    var viewDelegate: RoomInfoListViewModelViewDelegate? { get set }
    var coordinatorDelegate: RoomInfoListViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: RoomInfoListViewAction)    
}
