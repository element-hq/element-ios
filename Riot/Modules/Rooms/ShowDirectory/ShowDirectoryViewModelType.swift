// File created from ScreenTemplate
// $ createScreen.sh Rooms/ShowDirectory ShowDirectory
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol ShowDirectoryViewModelViewDelegate: AnyObject {
    func showDirectoryViewModel(_ viewModel: ShowDirectoryViewModelType, didUpdateViewState viewSate: ShowDirectoryViewState)
}

protocol ShowDirectoryViewModelCoordinatorDelegate: AnyObject {
    func showDirectoryViewModelDidSelect(_ viewModel: ShowDirectoryViewModelType, room: MXPublicRoom)
    func showDirectoryViewModel(_ viewModel: ShowDirectoryViewModelType, didSelectRoomWithIdOrAlias roomIdOrAlias: String)
    func showDirectoryViewModelDidTapCreateNewRoom(_ viewModel: ShowDirectoryViewModelType)
    func showDirectoryViewModelDidCancel(_ viewModel: ShowDirectoryViewModelType)
    func showDirectoryViewModelWantsToShowDirectoryServerPicker(_ viewModel: ShowDirectoryViewModelType)
}

/// Protocol describing the view model used by `ShowDirectoryViewController`
protocol ShowDirectoryViewModelType {        
        
    var viewDelegate: ShowDirectoryViewModelViewDelegate? { get set }
    var coordinatorDelegate: ShowDirectoryViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: ShowDirectoryViewAction)
    
    func updatePublicRoomsDataSource(with cellData: MXKDirectoryServerCellDataStoring)
}
