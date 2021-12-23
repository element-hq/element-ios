// File created from ScreenTemplate
// $ createScreen.sh CreateRoom/EnterNewRoomDetails EnterNewRoomDetails
/*
 Copyright 2020 New Vector Ltd
 
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

protocol EnterNewRoomDetailsViewModelViewDelegate: AnyObject {
    func enterNewRoomDetailsViewModel(_ viewModel: EnterNewRoomDetailsViewModelType, didUpdateViewState viewSate: EnterNewRoomDetailsViewState)
}

protocol EnterNewRoomDetailsViewModelCoordinatorDelegate: AnyObject {
    func enterNewRoomDetailsViewModel(_ viewModel: EnterNewRoomDetailsViewModelType, didCreateNewRoom room: MXRoom)
    func enterNewRoomDetailsViewModel(_ viewModel: EnterNewRoomDetailsViewModelType, didTapChooseAvatar sourceView: UIView)
    func enterNewRoomDetailsViewModelDidCancel(_ viewModel: EnterNewRoomDetailsViewModelType)
}

enum EnterNewRoomActionType {
    case createOnly
    case createAndAddToSpace
}

/// Protocol describing the view model used by `EnterNewRoomDetailsViewController`
protocol EnterNewRoomDetailsViewModelType {        
        
    var viewDelegate: EnterNewRoomDetailsViewModelViewDelegate? { get set }
    var coordinatorDelegate: EnterNewRoomDetailsViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: EnterNewRoomDetailsViewAction)
    
    var roomCreationParameters: RoomCreationParameters { get set }
    
    var viewState: EnterNewRoomDetailsViewState { get }
    
    var actionType: EnterNewRoomActionType { get }
}
