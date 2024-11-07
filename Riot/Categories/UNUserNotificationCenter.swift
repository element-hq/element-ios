/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation
import UserNotifications
import MatrixSDK

@objc extension UNUserNotificationCenter {
    
    func removeUnwantedNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { (notifications) in
            //  get identifiers of notifications whose category identifiers are "TO_BE_REMOVED"
            let identifiersToBeRemoved = notifications.compactMap({ $0.request.content.categoryIdentifier == Constants.toBeRemovedNotificationCategoryIdentifier ? $0.request.identifier : nil })
            
            MXLog.debug("[UNUserNotificationCenter] removeUnwantedNotifications: Removing \(identifiersToBeRemoved.count) notifications.")
            //  remove the notifications with these id's
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiersToBeRemoved)
        }
    }
    
    /// Remove call invite notifications for the given room id. If room id is not given. removes all call invite notifications.
    /// - Parameter roomId: Room identifier to be removed call invite notifications for.
    func removeCallNotifications(for roomId: String? = nil) {
        
        func notificationShouldBeRemoved(_ notification: UNNotification) -> Bool {
            if notification.request.content.categoryIdentifier != Constants.callInviteNotificationCategoryIdentifier {
                //  if not a call invite, should not be removed
                return false
            }
            
            guard let roomId = roomId else {
                //  if a room id not provided, should be removed
                return true
            }
            let roomIdInPush = notification.request.content.userInfo["room_id"] as? String
            return roomId == roomIdInPush
        }
        
        UNUserNotificationCenter.current().getDeliveredNotifications { (notifications) in
            //  get identifiers of notifications that should be removed
            let identifiersToBeRemoved = notifications.compactMap({ notificationShouldBeRemoved($0) ? $0.request.identifier : nil })

            MXLog.debug("[UNUserNotificationCenter] removeCallNotifications: Removing \(identifiersToBeRemoved.count) notifications.")
            //  remove the notifications with these id's
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiersToBeRemoved)
        }
    }
    
}
