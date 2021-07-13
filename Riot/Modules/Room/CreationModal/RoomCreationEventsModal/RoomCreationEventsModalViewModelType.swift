// File created from ScreenTemplate
// $ createScreen.sh Modal2/RoomCreation RoomCreationEventsModal
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

protocol RoomCreationEventsModalViewModelViewDelegate: AnyObject {
    func roomCreationEventsModalViewModel(_ viewModel: RoomCreationEventsModalViewModelType, didUpdateViewState viewSate: RoomCreationEventsModalViewState)
}

protocol RoomCreationEventsModalViewModelCoordinatorDelegate: AnyObject {
    func roomCreationEventsModalViewModelDidTapClose(_ viewModel: RoomCreationEventsModalViewModelType)
}

/// Protocol describing the view model used by `RoomCreationEventsModalViewController`
protocol RoomCreationEventsModalViewModelType {
        
    var viewDelegate: RoomCreationEventsModalViewModelViewDelegate? { get set }
    var coordinatorDelegate: RoomCreationEventsModalViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: RoomCreationEventsModalViewAction)
    var numberOfRows: Int { get }
    func rowViewModel(at indexPath: IndexPath) -> RoomCreationEventRowViewModel?
    var roomName: String? { get }
    var roomInfo: String? { get }
    func setAvatar(in avatarImageView: MXKImageView)
    func setEncryptionIcon(in imageView: UIImageView)
}
