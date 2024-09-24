// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceMembers/MemberList ShowSpaceMemberList
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol SpaceMemberListViewModelViewDelegate: AnyObject {
    func spaceMemberListViewModel(_ viewModel: SpaceMemberListViewModelType, didUpdateViewState viewSate: SpaceMemberListViewState)
}

protocol SpaceMemberListViewModelCoordinatorDelegate: AnyObject {
    func spaceMemberListViewModel(_ viewModel: SpaceMemberListViewModelType, didSelect member: MXRoomMember, from sourceView: UIView?)
    func spaceMemberListViewModelDidCancel(_ viewModel: SpaceMemberListViewModelType)
    func spaceMemberListViewModelShowInvite(_ viewModel: SpaceMemberListViewModelType)
}

/// Protocol describing the view model used by `SpaceMemberListViewController`
protocol SpaceMemberListViewModelType {        
        
    var viewDelegate: SpaceMemberListViewModelViewDelegate? { get set }
    var coordinatorDelegate: SpaceMemberListViewModelCoordinatorDelegate? { get set }
    var space: MXSpace? { get }
    
    func process(viewAction: SpaceMemberListViewAction)
}
