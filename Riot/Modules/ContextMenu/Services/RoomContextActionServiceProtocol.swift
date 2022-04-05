// 
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

@objc protocol RoomContextActionServiceDelegate {
    func roomContextActionService(_ service: RoomContextActionServiceProtocol, updateActivityIndicator isActive: Bool)
    func roomContextActionService(_ service: RoomContextActionServiceProtocol, presentAlert alertController: UIAlertController)
    func roomContextActionService(_ service: RoomContextActionServiceProtocol, showRoomNotificationSettingsForRoomWithId roomId: String)
    func roomContextActionServiceDidJoinRoom(_ service: RoomContextActionServiceProtocol)
    func roomContextActionServiceDidLeaveRoom(_ service: RoomContextActionServiceProtocol)
}

/// `RoomContextActionServiceProtocol` classes are meant to be called by a `RoomActionProviderProtocol` instance so it provides the implementation of the menu actions.
@objc protocol RoomContextActionServiceProtocol {
    var delegate: RoomContextActionServiceDelegate? { get set }
    var roomId: String { get }
    var session: MXSession { get }
}
