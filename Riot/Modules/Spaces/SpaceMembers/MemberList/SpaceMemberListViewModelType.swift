// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceMembers/MemberList ShowSpaceMemberList
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
