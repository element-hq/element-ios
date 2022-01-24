// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceMembers/MemberDetail ShowSpaceMemberDetail
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
