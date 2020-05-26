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
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var originalContent: UNMutableNotificationContent?
    
    var userAccount: MXKAccount?
    var store: MXFileStore?
    var showDecryptedContentInNotifications: Bool {
        return RiotSettings.shared.showDecryptedContentInNotifications
    }
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        //  save this content as fallback content
        originalContent = request.content.mutableCopy() as? UNMutableNotificationContent
        
        UNUserNotificationCenter.current().removeUnwantedNotifications()
        
        //  check if this is a Matrix notification
        guard let content = originalContent else {
            return
        }
        
        let userInfo = content.userInfo
        NSLog("[NotificationService] Payload came: \(userInfo)")
        let roomId = userInfo["room_id"] as? String
        let eventId = userInfo["event_id"] as? String

        guard roomId != nil, eventId != nil else {
            //  it's not a Matrix notification, do not change the content
            NSLog("[NotificationService] didReceiveRequest: This is not a Matrix notification.")
            contentHandler(content)
            return
        }
        
        //  setup user account
        setup()
        
        //  fetch the event first
        fetchEvent()
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        NSLog("[NotificationService] serviceExtensionTimeWillExpire")
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
        guard let content = originalContent, let userAccount = self.userAccount else {
            //  there is something wrong, do not change the content
            NSLog("[NotificationService] fetchEvent: Either originalContent or userAccount is missing.")
            fallbackToOriginalContent()
            return
        }
        let userInfo = content.userInfo
        
        guard let roomId = userInfo["room_id"] as? String, let eventId = userInfo["event_id"] as? String else {
            //  it's not a Matrix notification, do not change the content
            NSLog("[NotificationService] fetchEvent: This is not a Matrix notification.")
            contentHandler?(content)
            return
        }
        
        userAccount.mxSession.event(withEventId: eventId, inRoom: roomId, success: { [weak self] (event) in
            guard let self = self else {
                NSLog("[NotificationService] fetchEvent: MXSession.event method returned too late successfully.")
                return
            }
            
            guard let event = event else {
                self.fallbackToOriginalContent()
                return
            }
            
            guard event.isEncrypted else {
                //  not encrypted, go on processing
                self.processEvent(event)
                return
            }
            
            //  encrypted
            guard self.showDecryptedContentInNotifications else {
                //  do not show decrypted content in notification
                self.fallbackToOriginalContent()
                return
            }
            
            //  should show decrypted content in notification
            guard event.clear == nil else {
                //  already decrypted
                self.processEvent(event)
                return
            }
            
            //  should decrypt it first
            if userAccount.mxSession.decryptEvent(event, inTimeline: nil) {
                //  decryption succeeded
                self.processEvent(event)
            } else {
                //  decryption failed
                NSLog("[NotificationService] fetchEvent: Event needs to be decrpyted, but we don't have the keys to decrypt it. Launching a background sync.")
                self.launchBackgroundSync()
            }
        }) { [weak self] (error) in
            guard let self = self else {
                NSLog("[NotificationService] fetchEvent: MXSession.event method returned too late with error: \(String(describing: error))");
                return
            }
            NSLog("[NotificationService] fetchEvent: MXSession.event method returned error: \(String(describing: error))");
            self.fallbackToOriginalContent()
        }
    }
    
    func launchBackgroundSync() {
        guard let userAccount = userAccount else {
            self.fallbackToOriginalContent()
            return
        }
        guard let store = store else {
            self.fallbackToOriginalContent()
            return
        }
        if userAccount.mxSession == nil {
            userAccount.openSession(with: store)
        }

        //  launch an initial background sync
        userAccount.initialBackgroundSync(20000, success: { [weak self] in
            guard let self = self else {
                NSLog("[NotificationService] launchBackgroundSync: MXKAccount.initialBackgroundSync returned too late successfully")
                return
            }
            self.fetchEvent()
        }) { [weak self] (error) in
            guard let self = self else {
                NSLog("[NotificationService] launchBackgroundSync: MXKAccount.initialBackgroundSync returned too late with error: \(String(describing: error))")
                return
            }
            NSLog("[NotificationService] launchBackgroundSync: MXKAccount.initialBackgroundSync returned with error: \(String(describing: error))")
            self.fallbackToOriginalContent()
        }
    }
    
    func processEvent(_ event: MXEvent) {
        guard let content = originalContent, let userAccount = userAccount else {
            self.fallbackToOriginalContent()
            return
        }

        self.notificationContent(forEvent: event, inAccount: userAccount) { (notificationContent) in
            //  close store
            self.store?.close()
            
            // Modify the notification content here...
            if let newContent = notificationContent {
                content.title = newContent.title
                content.subtitle = newContent.subtitle
                content.body = newContent.body
                content.threadIdentifier = newContent.threadIdentifier
                content.categoryIdentifier = newContent.categoryIdentifier
                content.userInfo = newContent.userInfo
                content.sound = newContent.sound
            } else {
                //  this is an unwanted notification, mark as to be deleted when app is foregrounded again OR a new push came
                content.categoryIdentifier = Constants.toBeRemovedNotificationCategoryIdentifier
            }
            
            self.contentHandler?(content)
        }
    }
    
    func fallbackToOriginalContent() {
        store?.close()
        guard let content = originalContent else {
            NSLog("[NotificationService] fallbackToOriginalContent: Original content is missing.")
            return
        }
        
        //  call contentHandler
        contentHandler?(content)
    }
    
    func notificationContent(forEvent event: MXEvent, inAccount account: MXKAccount, onComplete: @escaping (UNNotificationContent?) -> Void) {
        guard let content = event.content, content.count > 0 else {
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
        
        room.state({ (roomState: MXRoomState!) in
            
            var notificationTitle: String?
            var notificationBody: String?
            
            var threadIdentifier = room.roomId
            let eventSenderName = roomState.members.memberName(event.sender)
            let currentUserId = account.mxCredentials.userId
            
            switch event.eventType {
            case .roomMessage, .roomEncrypted:
                if room.isMentionsOnly {
                    // A local notification will be displayed only for highlighted notification.
                    var isHighlighted = false
                    
                    // Check whether is there an highlight tweak on it
                    for ruleAction in pushRule?.actions ?? [] {
                        guard let action = ruleAction as? MXPushRuleAction else { continue }
                        guard action.actionType == MXPushRuleActionTypeSetTweak else { continue }
                        guard action.parameters["set_tweak"] as? String == "highlight" else { continue }
                        // Check the highlight tweak "value"
                        // If not present, highlight. Else check its value before highlighting
                        if nil == action.parameters["value"] || true == (action.parameters["value"] as? Bool) {
                            isHighlighted = true
                            break
                        }
                    }
                    
                    guard isHighlighted else {
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
                let myUserId = account.mxSession.myUser.userId
                let isIncomingEvent = event.sender != myUserId
                
                // Display the room name only if it is different than the sender name
                if roomDisplayName != nil && roomDisplayName != eventSenderName {
                    notificationTitle = NSString.localizedUserNotificationString(forKey: "MSG_FROM_USER_IN_ROOM_TITLE", arguments: [eventSenderName as Any, roomDisplayName as Any])
                    
                    if msgType == kMXMessageTypeText {
                        notificationBody = messageContent
                    } else if msgType == kMXMessageTypeEmote {
                        notificationBody = NSString.localizedUserNotificationString(forKey: "ACTION_FROM_USER", arguments: [eventSenderName as Any, messageContent as Any])
                    } else if msgType == kMXMessageTypeImage {
                        notificationBody = NSString.localizedUserNotificationString(forKey: "IMAGE_FROM_USER", arguments: [eventSenderName as Any, messageContent as Any])
                    } else if room.isDirect && isIncomingEvent && msgType == kMXMessageTypeKeyVerificationRequest {
                        account.mxSession.crypto.keyVerificationManager.keyVerification(fromKeyVerificationEvent: event,
                                                                                        success:{ (keyVerification) in
                            guard let request = keyVerification.request, request.state == MXKeyVerificationRequestStatePending else {
                                onComplete(nil)
                                return
                            }
                            // TODO: Add accept and decline actions to notification
                            let body = NSString.localizedUserNotificationString(forKey: "KEY_VERIFICATION_REQUEST_FROM_USER", arguments: [eventSenderName as Any])
                            
                            let notificationContent = self.notificationContent(withTitle: notificationTitle,
                                                                               body: body,
                                                                               threadIdentifier: threadIdentifier,
                                                                               userId: currentUserId,
                                                                               event: event,
                                                                               pushRule: pushRule)
                            
                            onComplete(notificationContent)
                        }, failure:{ (error) in
                            NSLog("[NotificationService][Push] notificationContentForEvent: failed to fetch key verification with error: \(error)")
                            onComplete(nil)
                        })
                    } else {
                        // Encrypted messages falls here
                        notificationBody = NSString.localizedUserNotificationString(forKey: "MSG_FROM_USER", arguments: [eventSenderName as Any])
                    }
                } else {
                    notificationTitle = eventSenderName
                    
                    switch msgType {
                    case kMXMessageTypeText:
                        notificationBody = messageContent
                        break
                    case kMXMessageTypeEmote:
                        notificationBody = NSString.localizedUserNotificationString(forKey: "ACTION_FROM_USER", arguments: [eventSenderName as Any, messageContent as Any])
                        break
                    case kMXMessageTypeImage:
                        notificationBody = NSString.localizedUserNotificationString(forKey: "IMAGE_FROM_USER", arguments: [eventSenderName as Any, messageContent as Any])
                        break
                    default:
                        // Encrypted messages falls here
                        notificationBody = NSString.localizedUserNotificationString(forKey: "MSG_FROM_USER", arguments: [eventSenderName as Any])
                        break
                    }
                }
                break
            case .callInvite:
                let offer = event.content["offer"] as? [AnyHashable: Any]
                let sdp = offer?["sdp"] as? String
                let isVideoCall = sdp?.contains("m=video") ?? false
                
                if isVideoCall {
                    notificationBody = NSString.localizedUserNotificationString(forKey: "VIDEO_CALL_FROM_USER", arguments: [eventSenderName as Any])
                } else {
                    notificationBody = NSString.localizedUserNotificationString(forKey: "VOICE_CALL_FROM_USER", arguments: [eventSenderName as Any])
                }
                
                // call notifications should stand out from normal messages, so we don't stack them
                threadIdentifier = nil
            case .roomMember:
                let roomDisplayName = room.summary.displayname
                
                if roomDisplayName != nil && roomDisplayName != eventSenderName {
                    notificationBody = NSString.localizedUserNotificationString(forKey: "USER_INVITE_TO_NAMED_ROOM", arguments: [eventSenderName as Any, roomDisplayName as Any])
                } else {
                    notificationBody = NSString.localizedUserNotificationString(forKey: "USER_INVITE_TO_CHAT", arguments: [eventSenderName as Any])
                }
            case .sticker:
                let roomDisplayName = room.summary.displayname
                
                if roomDisplayName != nil && roomDisplayName != eventSenderName {
                    notificationTitle = NSString.localizedUserNotificationString(forKey: "MSG_FROM_USER_IN_ROOM_TITLE", arguments: [eventSenderName as Any, roomDisplayName as Any])
                } else {
                    notificationTitle = eventSenderName
                }
                
                notificationBody = NSString.localizedUserNotificationString(forKey: "STICKER_FROM_USER", arguments: [eventSenderName as Any])
            default:
                break
            }
            
            guard (notificationBody != nil) else {
                onComplete(nil)
                return
            }
            
            let notificationContent = self.notificationContent(withTitle: notificationTitle,
                                                               body: notificationBody,
                                                               threadIdentifier: threadIdentifier,
                                                               userId: currentUserId,
                                                               event: event,
                                                               pushRule: pushRule)
            
            onComplete(notificationContent)
        })
    }
    
    func notificationContent(withTitle title: String?,
                             body: String?,
                             threadIdentifier: String?,
                             userId: String?,
                             event: MXEvent,
                             pushRule: MXPushRule?) -> UNNotificationContent {
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
            guard action.actionType == MXPushRuleActionTypeSetTweak else { continue }
            guard action.parameters["set_tweak"] as? String == "sound" else { continue }
            soundName = action.parameters["value"] as? String
            if soundName == "default" {
                soundName = "message.caf"
            }
        }
        
        return soundName
    }
    
    func notificationCategoryIdentifier(forEvent event: MXEvent) -> String? {
        let isNotificationContentShown = !event.isEncrypted || self.showDecryptedContentInNotifications
        
        guard isNotificationContentShown else {
            return nil
        }
        
        guard event.eventType == .roomMessage || event.eventType == .roomEncrypted else {
            return nil
        }
        
        return "QUICK_REPLY"
    }
    
}

extension MXRoom {
    
    func getRoomPushRule() -> MXPushRule? {
        guard let rules = self.mxSession.notificationCenter.rules.global.room else {
            return nil
        }
        
        for rule in rules {
            guard let pushRule = rule as? MXPushRule else { continue }
            // the rule id is the room Id
            // it is the server trick to avoid duplicated rule on the same room.
            if pushRule.ruleId == self.roomId {
                return pushRule
            }
        }

        return nil
    }

    var isMentionsOnly: Bool {
        // Check push rules at room level
        guard let rule = self.getRoomPushRule() else {
            return false
        }
        
        for ruleAction in rule.actions {
            guard let action = ruleAction as? MXPushRuleAction else { continue }
            if action.actionType == MXPushRuleActionTypeDontNotify {
                return rule.enabled
            }
        }

        return false
    }
    
}
