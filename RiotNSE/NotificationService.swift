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

import UserNotifications
import MatrixKit

class NotificationService: UNNotificationServiceExtension {
    
    var requestIdentifier: String?
    var contentHandler: ((UNNotificationContent) -> Void)?
    var originalContent: UNMutableNotificationContent?
    
    var userAccount: MXKAccount?
    var store: MXFileStore?
    var showDecryptedContentInNotifications: Bool {
        return RiotSettings.shared.showDecryptedContentInNotifications
    }
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        requestIdentifier = request.identifier
        //  save this content as fallback content
        originalContent = request.content.mutableCopy() as? UNMutableNotificationContent
        
        //  check if this is a Matrix notification
        if let content = originalContent {
            let userInfo = content.userInfo
            NSLog("[NotificationService] Payload came: \(userInfo) with identifier: \(requestIdentifier!)")
            let roomId = userInfo["room_id"] as? String
            let eventId = userInfo["event_id"] as? String
            
            guard roomId != nil, eventId != nil else {
                //  it's not a Matrix notification, do not change the content
                NSLog("[NotificationService] Fallback case 7")
                contentHandler(content)
                return
            }
        }
        
        //  setup user account
        setup()
        
        //  fetch the event first
        fetchEvent()
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        NSLog("[NotificationService] Fallback case 5")
        fallbackToOriginalContent()
    }
    
    func setup() {
        let sdkOptions = MXSDKOptions.sharedInstance()
        sdkOptions.applicationGroupIdentifier = "group.im.vector"
        sdkOptions.disableIdenticonUseForUserAvatar = true
        sdkOptions.enableCryptoWhenStartingMXSession = true
        sdkOptions.backgroundModeHandler = MXUIKitBackgroundModeHandler()
        Bundle.mxk_customizeLocalizedStringTableName("Vector")
        
        if isatty(STDERR_FILENO) == 0 {
            MXLogger.setSubLogName("nse")
            MXLogger.redirectNSLog(toFiles: true)
        }
        
        userAccount = MXKAccountManager.shared()?.activeAccounts.first
        
        if let userAccount = userAccount {
            store = MXFileStore(credentials: userAccount.mxCredentials)
            
            if userAccount.mxSession == nil {
                userAccount.openSession(with: store!)
            }
        }
    }
    
    func fetchEvent() {
        if let content = originalContent, let userAccount = self.userAccount {
            let userInfo = content.userInfo
            
            guard let roomId = userInfo["room_id"] as? String, let eventId = userInfo["event_id"] as? String else {
                //  it's not a Matrix notification, do not change the content
                NSLog("[NotificationService] Fallback case 1")
                contentHandler?(content)
                return
            }
            
            userAccount.mxSession.event(withEventId: eventId, inRoom: roomId, success: { [weak self] (event) in
                guard let self = self else {
                    NSLog("[NotificationService] Fallback case 9")
                    return
                }
                
                guard let event = event else {
                    return
                }
                
                if event.isEncrypted {
                    //  encrypted
                    if self.showDecryptedContentInNotifications {
                        //  should show decrypted content in notification
                        if event.clear == nil {
                            //  should decrypt it first
                            if userAccount.mxSession.decryptEvent(event, inTimeline: nil) {
                                //  decryption succeeded
                                self.processEvent(event)
                            } else {
                                //  decryption failed
                                NSLog("[NotificationService] Event needs to be decrpyted, but we don't have the keys to decrypt it. Launching a background sync.")
                                self.launchBackgroundSync()
                            }
                        } else {
                            //  already decrypted
                            self.processEvent(event)
                        }
                    } else {
                        //  do not show decrypted content in notification
                        self.fallbackToOriginalContent()
                    }
                } else {
                    //  not encrypted, go on
                    self.processEvent(event)
                }
            }) { [weak self] (error) in
                guard let self = self else {
                    NSLog("[NotificationService] Fallback case 10")
                    return
                }
                NSLog("[NotificationService] Fallback case 3")
                self.fallbackToOriginalContent()
            }
        } else {
            //  there is something wrong, do not change the content
            NSLog("[NotificationService] Fallback case 4")
            fallbackToOriginalContent()
        }
    }
    
    func launchBackgroundSync() {
        guard let userAccount = userAccount else { return }
        guard let store = store else { return }
        if userAccount.mxSession == nil {
            userAccount.openSession(with: store)
        }
        let sessionState = userAccount.mxSession.state
        if sessionState == MXSessionStateInitialised || sessionState == MXSessionStatePaused {
            userAccount.initialBackgroundSync(20000, success: { [weak self] in
                guard let self = self else {
                    NSLog("[NotificationService] Fallback case 12")
                    return
                }
                self.fetchEvent()
            }) { [weak self] (error) in
                guard let self = self else {
                    NSLog("[NotificationService] Fallback case 11")
                    return
                }
                NSLog("[NotificationService] Fallback case 6")
                self.fallbackToOriginalContent()
            }
        } else {
            NSLog("[NotificationService] Fallback case 8")
            fallbackToOriginalContent()
        }
    }
    
    func processEvent(_ event: MXEvent) {
        if let content = originalContent, let userAccount = userAccount, let requestIdentifier = requestIdentifier {
            
            self.notificationContent(forEvent: event, inAccount: userAccount) { (notificationContent) in
                self.store?.close()
                
                // Modify the notification content here...
                guard let newContent = notificationContent else {
                    //  remove
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [requestIdentifier])
                    return
                }
                
                content.title = newContent.title
                content.subtitle = newContent.subtitle
                content.body = newContent.body
                content.threadIdentifier = newContent.threadIdentifier
                content.categoryIdentifier = newContent.categoryIdentifier
                content.userInfo = newContent.userInfo
                content.sound = newContent.sound
                
                self.contentHandler?(content)
            }
        }
    }
    
    func fallbackToOriginalContent() {
        store?.close()
        if let content = originalContent {
            contentHandler?(content)
        } else {
            NSLog("[NotificationService] Fallback case 13")
        }
    }
    
    func notificationContent(forEvent event: MXEvent, inAccount account: MXKAccount, onComplete: @escaping (UNNotificationContent?) -> Void) {
        if event.content == nil || event.content!.count == 0 {
            NSLog("[NotificationService][Push] notificationContentForEvent: empty event content")
            onComplete(nil)
            return
        }
        
        guard let room = account.mxSession.room(withRoomId: event.roomId) else {
            NSLog("[NotificationService][Push] notificationBodyForEvent: Unknown room")
            onComplete(nil)
            return
        }
        let pushRule = room.getRoomPushRule()
        
        room.state({ (roomState:MXRoomState!) in
            
            var notificationTitle: String?
            var notificationBody: String?
            
            var threadIdentifier = room.roomId
            let eventSenderName = roomState.members.memberName(event.sender)
            let currentUserId = account.mxCredentials.userId
            
            if event.eventType == .roomMessage || event.eventType == .roomEncrypted {
                if room.isMentionsOnly {
                    // A local notification will be displayed only for highlighted notification.
                    var isHighlighted:Bool = false
                    
                    // Check whether is there an highlight tweak on it
                    for ruleAction in pushRule?.actions ?? [] {
                        guard let action = ruleAction as? MXPushRuleAction else { continue }
                        if action.actionType == MXPushRuleActionTypeSetTweak {
                            if action.parameters["set_tweak"] as? String == "highlight" {
                                // Check the highlight tweak "value"
                                // If not present, highlight. Else check its value before highlighting
                                if nil == action.parameters["value"] || true == (action.parameters["value"] as? Bool) {
                                    isHighlighted = true
                                    break
                                }
                            }
                        }
                    }
                    
                    if !isHighlighted {
                        // Ignore this notif.
                        NSLog("[NotificationService][Push] notificationBodyForEvent: Ignore non highlighted notif in mentions only room")
                        onComplete(nil)
                        return
                    }
                }
                
                var msgType = event.content["msgtype"] as? String
                let messageContent = event.content["body"] as? String
                
                if event.isEncrypted && !self.showDecryptedContentInNotifications {
                    // Hide the content
                    msgType = nil
                }
                
                let roomDisplayName = room.summary.displayname
                
                let myUserId:String! = account.mxSession.myUser.userId
                let isIncomingEvent:Bool = !(event.sender == myUserId)
                
                // Display the room name only if it is different than the sender name
                if roomDisplayName != nil && !(roomDisplayName == eventSenderName) {
                    notificationTitle = NSString.localizedUserNotificationString(forKey: "MSG_FROM_USER_IN_ROOM_TITLE", arguments:[eventSenderName as Any, roomDisplayName as Any])
                    
                    if (msgType == "m.text") {
                        notificationBody = messageContent
                    } else if (msgType == "m.emote") {
                        notificationBody = NSString.localizedUserNotificationString(forKey: "ACTION_FROM_USER", arguments:[eventSenderName as Any, messageContent as Any])
                    } else if (msgType == "m.image") {
                        notificationBody = NSString.localizedUserNotificationString(forKey: "IMAGE_FROM_USER", arguments:[eventSenderName as Any, messageContent as Any])
                    } else if room.isDirect && isIncomingEvent && (msgType == kMXMessageTypeKeyVerificationRequest) {
                        account.mxSession.crypto.keyVerificationManager.keyVerification(fromKeyVerificationEvent: event,
                                                                                        success:{ (keyVerification) in
                            if keyVerification.request != nil && keyVerification.request!.state == MXKeyVerificationRequestStatePending {
                                // TODO: Add accept and decline actions to notification
                                let body:String! = NSString.localizedUserNotificationString(forKey: "KEY_VERIFICATION_REQUEST_FROM_USER", arguments:[eventSenderName as Any])
                                
                                let notificationContent:UNNotificationContent! = self.notificationContent(withTitle: notificationTitle,
                                                                                                          body: body,
                                                                                                          threadIdentifier: threadIdentifier,
                                                                                                          userId: currentUserId,
                                                                                                          event: event,
                                                                                                          pushRule: pushRule)
                                
                                onComplete(notificationContent)
                            } else {
                                onComplete(nil)
                                                                                            }
                        }, failure:{ (error) in
                            NSLog("[NotificationService][Push] notificationContentForEvent: failed to fetch key verification with error: \(error)")
                            onComplete(nil)
                        })
                    } else {
                        // Encrypted messages falls here
                        notificationBody = NSString.localizedUserNotificationString(forKey: "MSG_FROM_USER", arguments:[eventSenderName as Any])
                    }
                } else {
                    notificationTitle = eventSenderName
                    
                    if (msgType == "m.text") {
                        notificationBody = messageContent
                    } else if (msgType == "m.emote") {
                        notificationBody = NSString.localizedUserNotificationString(forKey: "ACTION_FROM_USER", arguments:[eventSenderName as Any, messageContent as Any])
                    } else if (msgType == "m.image") {
                        notificationBody = NSString.localizedUserNotificationString(forKey: "IMAGE_FROM_USER", arguments:[eventSenderName as Any, messageContent as Any])
                    } else {
                        // Encrypted messages falls here
                        notificationBody = NSString.localizedUserNotificationString(forKey: "MSG_FROM_USER", arguments:[eventSenderName as Any])
                    }
                }
            } else if event.eventType == .callInvite {
                let offer = event.content["offer"] as? [AnyHashable: Any]
                let sdp = offer?["sdp"] as? String
                let isVideoCall = sdp?.contains("m=video") ?? false
                
                if isVideoCall {
                    notificationBody = NSString.localizedUserNotificationString(forKey: "VIDEO_CALL_FROM_USER", arguments:[eventSenderName as Any])
                } else {
                    notificationBody = NSString.localizedUserNotificationString(forKey: "VOICE_CALL_FROM_USER", arguments:[eventSenderName as Any])
                }
                
                // call notifications should stand out from normal messages, so we don't stack them
                threadIdentifier = nil
            } else if event.eventType == .roomMember {
                let roomDisplayName:String! = room.summary.displayname
                
                if roomDisplayName != nil && !(roomDisplayName == eventSenderName) {
                    notificationBody = NSString.localizedUserNotificationString(forKey: "USER_INVITE_TO_NAMED_ROOM", arguments:[eventSenderName as Any, roomDisplayName as Any])
                } else {
                    notificationBody = NSString.localizedUserNotificationString(forKey: "USER_INVITE_TO_CHAT", arguments:[eventSenderName as Any])
                }
            } else if event.eventType == .sticker {
                let roomDisplayName:String! = room.summary.displayname
                
                if roomDisplayName != nil && !(roomDisplayName == eventSenderName) {
                    notificationTitle = NSString.localizedUserNotificationString(forKey: "MSG_FROM_USER_IN_ROOM_TITLE", arguments:[eventSenderName as Any, roomDisplayName as Any])
                } else {
                    notificationTitle = eventSenderName
                }
                
                notificationBody = NSString.localizedUserNotificationString(forKey: "STICKER_FROM_USER", arguments:[eventSenderName as Any])
            }
            
            if (notificationBody != nil) {
                let notificationContent = self.notificationContent(withTitle: notificationTitle,
                                                                   body: notificationBody,
                                                                   threadIdentifier: threadIdentifier,
                                                                   userId: currentUserId,
                                                                   event: event,
                                                                   pushRule: pushRule)
                
                onComplete(notificationContent)
            } else {
                onComplete(nil)
            }
        })
    }
    
    func notificationContent(withTitle title: String?, body: String?, threadIdentifier: String?, userId: String?, event: MXEvent, pushRule: MXPushRule?) -> UNNotificationContent {
        let notificationContent = UNMutableNotificationContent()
        
        if let title = title {
            notificationContent.title = title
        }
        if let body = body {
            notificationContent.body = body
        }
        if let threadIdentifier = threadIdentifier {
            notificationContent.threadIdentifier = threadIdentifier
        }
        if let categoryIdentifier = self.notificationCategoryIdentifier(forEvent: event) {
            notificationContent.categoryIdentifier = categoryIdentifier
        }
        if let soundName = notificationSoundName(fromPushRule: pushRule) {
            notificationContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundName))
        } else {
            notificationContent.sound = UNNotificationSound.default
        }
        notificationContent.userInfo = notificationUserInfo(forEvent: event, andUserId: userId)
        
        return notificationContent
    }
    
    func notificationUserInfo(forEvent event: MXEvent, andUserId userId: String?) -> [AnyHashable: Any] {
        var notificationUserInfo: [AnyHashable: Any] = [
            "type": "full",
            "room_id": event.roomId as Any,
            "event_id": event.eventId as Any
        ]
        if let userId = userId {
            notificationUserInfo["user_id"] = userId
        }
        return notificationUserInfo
    }
    
    func notificationSoundName(fromPushRule pushRule: MXPushRule?) -> String? {
        var soundName: String?
        
        // Set sound name based on the value provided in action of MXPushRule
        for ruleAction in pushRule?.actions ?? [] {
            guard let action = ruleAction as? MXPushRuleAction else { continue }
            
            if action.actionType == MXPushRuleActionTypeSetTweak {
                if (action.parameters["set_tweak"] as? String == "sound") {
                    soundName = action.parameters["value"] as? String
                    if (soundName == "default") {
                        soundName = "message.caf"
                    }
                }
            }
        }
        
        return soundName
    }
    
    func notificationCategoryIdentifier(forEvent event: MXEvent) -> String? {
        let isNotificationContentShown = !event.isEncrypted || self.showDecryptedContentInNotifications
        
        var categoryIdentifier: String?
        
        if (event.eventType == .roomMessage || event.eventType == .roomEncrypted) && isNotificationContentShown {
            categoryIdentifier = "QUICK_REPLY"
        }
        
        return categoryIdentifier
    }
    
}

extension MXRoom {
    
    func getRoomPushRule() -> MXPushRule? {
        if let rules = self.mxSession.notificationCenter.rules.global.room {
            for rule in rules {
                guard let pushRule = rule as? MXPushRule else { continue }
                // the rule id is the room Id
                // it is the server trick to avoid duplicated rule on the same room.
                if (pushRule.ruleId == self.roomId) {
                    return pushRule
                }
            }
        }

        return nil
    }

    var isMentionsOnly: Bool {
        // Check push rules at room level
        if let rule = self.getRoomPushRule() {
            for ruleAction in rule.actions {
                guard let action = ruleAction as? MXPushRuleAction else { continue }
                if action.actionType == MXPushRuleActionTypeDontNotify {
                    return rule.enabled
                }
            }
        }

        return false
    }
    
}
