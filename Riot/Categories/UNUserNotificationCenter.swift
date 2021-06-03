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
