// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceRoomList/SpaceChildRoomDetail ShowSpaceChildRoomDetail
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

protocol ShowSpaceChildRoomDetailViewModelViewDelegate: AnyObject {
    func showSpaceChildRoomDetailViewModel(_ viewModel: ShowSpaceChildRoomDetailViewModelType, didUpdateViewState viewSate: ShowSpaceChildRoomDetailViewState)
}

protocol ShowSpaceChildRoomDetailViewModelCoordinatorDelegate: AnyObject {
    func showSpaceChildRoomDetailViewModelDidComplete(_ viewModel: ShowSpaceChildRoomDetailViewModelType, openRoomWith roomId: String)
    func showSpaceChildRoomDetailViewModelDidCancel(_ viewModel: ShowSpaceChildRoomDetailViewModelType)
}

/// Protocol describing the view model used by `ShowSpaceChildRoomDetailViewController`
protocol ShowSpaceChildRoomDetailViewModelType {        
        
    var viewDelegate: ShowSpaceChildRoomDetailViewModelViewDelegate? { get set }
    var coordinatorDelegate: ShowSpaceChildRoomDetailViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: ShowSpaceChildRoomDetailViewAction)
}
