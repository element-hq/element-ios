// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceMembers/MemberDetail ShowSpaceMemberDetail
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol SpaceMemberDetailViewModelViewDelegate: AnyObject {
    func spaceMemberDetailViewModel(_ viewModel: SpaceMemberDetailViewModelType, didUpdateViewState viewSate: SpaceMemberDetailViewState)
}

protocol SpaceMemberDetailViewModelCoordinatorDelegate: AnyObject {
    func spaceMemberDetailViewModel(_ viewModel: SpaceMemberDetailViewModelType, showRoomWithId roomId: String)
    func spaceMemberDetailViewModelDidCancel(_ viewModel: SpaceMemberDetailViewModelType)
}

/// Protocol describing the view model used by `SpaceMemberDetailViewController`
protocol SpaceMemberDetailViewModelType {        
        
    var viewDelegate: SpaceMemberDetailViewModelViewDelegate? { get set }
    var coordinatorDelegate: SpaceMemberDetailViewModelCoordinatorDelegate? { get set }
    var showCancelMenuItem: Bool { get }
    
    func process(viewAction: SpaceMemberDetailViewAction)
}
