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

protocol ShowSpaceMemberListViewModelViewDelegate: AnyObject {
    func showSpaceMemberListViewModel(_ viewModel: ShowSpaceMemberListViewModelType, didUpdateViewState viewSate: ShowSpaceMemberListViewState)
}

protocol ShowSpaceMemberListViewModelCoordinatorDelegate: AnyObject {
    func showSpaceMemberListViewModel(_ viewModel: ShowSpaceMemberListViewModelType, didSelect member: MXRoomMember, from sourceView: UIView?)
    func showSpaceMemberListViewModelDidCancel(_ viewModel: ShowSpaceMemberListViewModelType)
}

/// Protocol describing the view model used by `ShowSpaceMemberListViewController`
protocol ShowSpaceMemberListViewModelType {        
        
    var viewDelegate: ShowSpaceMemberListViewModelViewDelegate? { get set }
    var coordinatorDelegate: ShowSpaceMemberListViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: ShowSpaceMemberListViewAction)
}
