// 
// Copyright 2021 New Vector Ltd
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
import CoreSpotlight
import MatrixSDK

@objcMembers
class UserActivityService: NSObject {
    
    // MARK: - Properties
    
    #warning("This is initialised lazily so currently only observes left rooms if RoomViewController has been presented.")
    static let shared = UserActivityService()
    
    // MARK: - Setup
    
    private override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didLeaveRoom(_:)), name: .mxSessionDidLeaveRoom, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didLogOut(_:)), name: .mxkAccountManagerDidRemoveAccount, object: nil)
    }
    
    // MARK: - Public
    
    func update(_ userActivity: NSUserActivity, from room: MXRoom) {
        userActivity.title = room.summary.displayname
        
        userActivity.requiredUserInfoKeys = [ UserActivityField.room.rawValue ]
        var userInfo = [String: Any]()
        userInfo[UserActivityField.room.rawValue] = room.roomId
        if room.isDirect {
            userInfo[UserActivityField.user.rawValue] = room.directUserId
        }
        userActivity.userInfo = userInfo
        
        // TODO: if we add more userActivities, a `org.matrix.room` prefix should probably be added
        userActivity.persistentIdentifier = room.roomId
        
        userActivity.isEligibleForHandoff = true
        userActivity.isEligibleForSearch = true
        userActivity.isEligibleForPrediction = true
        
        var contentAttributes: CSSearchableItemAttributeSet
        if #available(iOS 14.0, *) {
            contentAttributes = CSSearchableItemAttributeSet(contentType: UTType.item)
        } else {
            contentAttributes = CSSearchableItemAttributeSet(itemContentType: "public.item")
        }
        
        contentAttributes.title = room.summary.displayname
        contentAttributes.displayName = room.summary.displayname
        contentAttributes.contentDescription = room.summary.lastMessage.text
        // TODO: contentAttributes.thumbnailURL
        contentAttributes.domainIdentifier = room.roomId
        contentAttributes.relatedUniqueIdentifier = room.summary.lastMessage.eventId
        // TODO: contentAttributes.weakRelatedUniqueIdentifier (is this needed? does it break anything else?)
        contentAttributes.instantMessageAddresses = [ room.roomId ]
        
        userActivity.contentAttributeSet = contentAttributes
    }
    
    func didLeaveRoom(_ notification: Notification) {
        guard let roomId = notification.userInfo?[kMXSessionNotificationRoomIdKey] as? String else { return }
        NSUserActivity.deleteSavedUserActivities(withPersistentIdentifiers: [roomId], completionHandler: { })
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [roomId], completionHandler: nil)
    }

    func didLogOut(_ notification: Notification) {
        NSUserActivity.deleteAllSavedUserActivities(completionHandler: { })
        CSSearchableIndex.default().deleteAllSearchableItems(completionHandler: nil)
    }
}
