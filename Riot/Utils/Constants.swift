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

@objcMembers
class Constants: NSObject {
    
    static let toBeRemovedNotificationCategoryIdentifier: String = "TO_BE_REMOVED"
    static let callInviteNotificationCategoryIdentifier: String = "CALL_INVITE"
    
    /// Notification userInfo key to present a notification when the app is on foreground. Value should be set as a Bool for this key.
    static let userInfoKeyPresentNotificationOnForeground: String = "ALWAYS_PRESENT_NOTIFICATION"
    
    /// Notification userInfo key to present a notification even if the app is on foreground and in the notification's room screen. Value should be set as a Bool for this key.
    static let userInfoKeyPresentNotificationInRoom: String = "IN_ROOM_PRESENT_NOTIFICATION"
    
}
