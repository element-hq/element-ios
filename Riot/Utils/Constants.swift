/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
