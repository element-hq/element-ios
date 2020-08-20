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
import MatrixSDK

class NotificationService: UNNotificationServiceExtension {
    
    /// Content handlers. Keys are eventId's
    var contentHandlers: [String: ((UNNotificationContent) -> Void)] = [:]
    
    /// Best attempt contents. Will be updated incrementally, if something fails during the process, this best attempt content will be showed as notification. Keys are eventId's
    var bestAttemptContents: [String: UNMutableNotificationContent] = [:]
    
    /// Cached events. Keys are eventId's
    var cachedEvents: [String: MXEvent] = [:]
    static var mxSession: MXSession?
    var showDecryptedContentInNotifications: Bool {
        return RiotSettings.shared.showDecryptedContentInNotifications
    }
    lazy var configuration: Configurable = {
        return CommonConfiguration()
    }()
    static var isLoggerInitialized: Bool = false
    private lazy var pushGatewayRestClient: MXPushGatewayRestClient = {
        let url = URL(string: BuildSettings.serverConfigSygnalAPIUrlString)!
        return MXPushGatewayRestClient(pushGateway: url.scheme! + "://" + url.host!, andOnUnrecognizedCertificateBlock: nil)
    }()
    private var pushNotificationStore: PushNotificationStore = PushNotificationStore()
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        // Set static application settings
        configuration.setupSettings()
        
        if DataProtectionHelper.isDeviceInRebootedAndLockedState(appGroupIdentifier: MXSDKOptions.sharedInstance().applicationGroupIdentifier) {
            //  kill the process in this state, this leads for the notification to be displayed as came from APNS
            exit(0)
        }
        
        //  setup logs
        setupLogger()
        
        NSLog("[NotificationService] Instance: \(self), thread: \(Thread.current)")

        UNUserNotificationCenter.current().removeUnwantedNotifications()
        
        let userInfo = request.content.userInfo
        NSLog("[NotificationService] Payload came: \(userInfo)")

        //  check if this is a Matrix notification
        guard let roomId = userInfo["room_id"] as? String, let eventId = userInfo["event_id"] as? String else {
            //  it's not a Matrix notification, do not change the content
            NSLog("[NotificationService] didReceiveRequest: This is not a Matrix notification.")
            contentHandler(request.content)
            return
        }
        
        //  save this content as fallback content
        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
            return
        }
        
        //  read badge from "unread_count"
        //  no need to check before, if it's nil, the badge will remain unchanged
        content.badge = userInfo["unread_count"] as? NSNumber
        
        bestAttemptContents[eventId] = content
        contentHandlers[eventId] = contentHandler
        
        //  setup user account
        setup(withRoomId: roomId, eventId: eventId) {
            //  preprocess the payload, will attempt to fetch room display name
            self.preprocessPayload(forEventId: eventId, roomId: roomId)
            //  fetch the event first
            self.fetchEvent(withEventId: eventId, roomId: roomId)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        
        NSLog("[NotificationService] serviceExtensionTimeWillExpire")
        //  No-op here. If the process is killed by the OS due to time limit, it will also show the notification with the original content.
    }
    
    func setupLogger() {
        if !NotificationService.isLoggerInitialized {
            if isatty(STDERR_FILENO) == 0 {
                MXLogger.setSubLogName("nse")
                MXLogger.redirectNSLog(toFiles: true)
            }
            NotificationService.isLoggerInitialized = true
        }
    }
    
    func setup(withRoomId roomId: String, eventId: String, completion: @escaping () -> Void) {
        if let userAccount = MXKAccountManager.shared()?.activeAccounts.first {
            if NotificationService.mxSession == nil {
                let store = NSEMemoryStore(withCredentials: userAccount.mxCredentials)
                NotificationService.mxSession = MXSession(matrixRestClient: MXRestClient(credentials: userAccount.mxCredentials, unrecognizedCertificateHandler: nil))
                NotificationService.mxSession?.setStore(store, completion: { (response) in
                    switch response {
                    case .success:
                        completion()
                        break
                    case .failure(let error):
                        NSLog("[NotificationService] setup: MXSession.setStore method returned error: \(String(describing: error))")
                        self.fallbackToBestAttemptContent(forEventId: eventId)
                        break
                    }
                })
            } else {
                NSLog("[NotificationService] Instance: Reusing session")
                completion()
            }
        } else {
            NSLog("[NotificationService] setup: No active accounts")
            fallbackToBestAttemptContent(forEventId: eventId)
        }
    }
    
    /// Attempts to preprocess payload and attach room display name to the best attempt content
    /// - Parameters:
    ///   - eventId: Event identifier to mutate best attempt content
    ///   - roomId: Room identifier to fetch display name
    func preprocessPayload(forEventId eventId: String, roomId: String) {
        guard let session = NotificationService.mxSession else { return }
        guard let roomDisplayName = session.store.summary?(ofRoom: roomId)?.displayname else { return }
        let isDirect = session.directUserId(inRoom: roomId) != nil
        if isDirect {
            bestAttemptContents[eventId]?.body = NSString.localizedUserNotificationString(forKey: "MESSAGE_FROM_X", arguments: [roomDisplayName as Any])
        } else {
            bestAttemptContents[eventId]?.body = NSString.localizedUserNotificationString(forKey: "MESSAGE_IN_X", arguments: [roomDisplayName as Any])
        }
    }
    
    func fetchEvent(withEventId eventId: String, roomId: String) {
        guard let mxSession = NotificationService.mxSession else {
            //  there is something wrong, do not change the content
            NSLog("[NotificationService] fetchEvent: Either originalContent or mxSession is missing.")
            fallbackToBestAttemptContent(forEventId: eventId)
            return
        }

        /// Inline function to handle encryption for event, either from cache or from the backend
        /// - Parameter event: The event to be handled
        func handleEncryption(forEvent event: MXEvent) {
            if !event.isEncrypted {
                //  not encrypted, go on processing
                NSLog("[NotificationService] fetchEvent: Event not encrypted.")
                self.processEvent(event)
                return
            }
            
            //  encrypted
            if event.clear != nil {
                //  already decrypted
                NSLog("[NotificationService] fetchEvent: Event already decrypted.")
                self.processEvent(event)
                return
            }
            
            //  should decrypt it first
            if mxSession.decryptEvent(event, inTimeline: nil) {
                //  decryption succeeded
                NSLog("[NotificationService] fetchEvent: Event decrypted successfully.")
                self.processEvent(event)
            } else {
                //  decryption failed
                NSLog("[NotificationService] fetchEvent: Event needs to be decrpyted, but we don't have the keys to decrypt it. Launching a background sync.")
                self.launchBackgroundSync(forEventId: eventId, roomId: roomId)
            }
        }
        
        //  check if we've fetched the event before
        if let cachedEvent = self.cachedEvents[eventId] {
            //  use cached event
            handleEncryption(forEvent: cachedEvent)
        } else {
            //  attempt to fetch the event
            mxSession.event(withEventId: eventId, inRoom: roomId, success: { [weak self] (event) in
                guard let self = self else {
                    NSLog("[NotificationService] fetchEvent: MXSession.event method returned too late successfully.")
                    return
                }
                
                guard let event = event else {
                    NSLog("[NotificationService] fetchEvent: MXSession.event method returned successfully with no event.")
                    self.fallbackToBestAttemptContent(forEventId: eventId)
                    return
                }
                
                //  cache this event
                self.cachedEvents[eventId] = event
                
                //  handle encryption for this event
                handleEncryption(forEvent: event)
            }) { [weak self] (error) in
                guard let self = self else {
                    NSLog("[NotificationService] fetchEvent: MXSession.event method returned too late with error: \(String(describing: error))")
                    return
                }
                NSLog("[NotificationService] fetchEvent: MXSession.event method returned error: \(String(describing: error))")
                self.fallbackToBestAttemptContent(forEventId: eventId)
            }
        }
    }
    
    func launchBackgroundSync(forEventId eventId: String, roomId: String) {
        guard let mxSession = NotificationService.mxSession else {
            NSLog("[NotificationService] launchBackgroundSync: mxSession is missing.")
            self.fallbackToBestAttemptContent(forEventId: eventId)
            return
        }

        //  launch an initial background sync
        mxSession.backgroundSync(withTimeout: 20, ignoreSessionState: true) { [weak self] (response) in
            switch response {
            case .success:
                guard let self = self else {
                    NSLog("[NotificationService] launchBackgroundSync: MXSession.initialBackgroundSync returned too late successfully")
                    return
                }
                self.fetchEvent(withEventId: eventId, roomId: roomId)
                break
            case .failure(let error):
                guard let self = self else {
                    NSLog("[NotificationService] launchBackgroundSync: MXSession.initialBackgroundSync returned too late with error: \(String(describing: error))")
                    return
                }
                NSLog("[NotificationService] launchBackgroundSync: MXSession.initialBackgroundSync returned with error: \(String(describing: error))")
                self.fallbackToBestAttemptContent(forEventId: eventId)
                break
            }
        }
    }
    
    func processEvent(_ event: MXEvent) {
        guard let content = bestAttemptContents[event.eventId], let mxSession = NotificationService.mxSession else {
            self.fallbackToBestAttemptContent(forEventId: event.eventId)
            return
        }

        self.notificationContent(forEvent: event, inSession: mxSession) { (notificationContent) in
            var isUnwantedNotification = false
            
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
                isUnwantedNotification = true
            }
            
            NSLog("[NotificationService] processEvent: Calling content handler for: \(String(describing: event.eventId)), isUnwanted: \(isUnwantedNotification)")
            self.contentHandlers[event.eventId]?(content)
        }
    }
    
    func fallbackToBestAttemptContent(forEventId eventId: String) {
        NSLog("[NotificationService] fallbackToBestAttemptContent: method called.")
        
        guard let content = bestAttemptContents[eventId] else {
            NSLog("[NotificationService] fallbackToBestAttemptContent: Best attempt content is missing.")
            return
        }
        
        //  call contentHandler
        contentHandlers[eventId]?(content)
    }
    
    func notificationContent(forEvent event: MXEvent, inSession session: MXSession, onComplete: @escaping (UNNotificationContent?) -> Void) {
        guard let content = event.content, content.count > 0 else {
            NSLog("[NotificationService] notificationContentForEvent: empty event content")
            onComplete(nil)
            return
        }
        guard let room = MXRoom.load(from: session.store, withRoomId: event.roomId, matrixSession: session) as? MXRoom else {
            NSLog("[NotificationService] notificationContentForEvent: Unknown room")
            onComplete(nil)
            return
        }
        
        NSLog("[NotificationService] notificationContentForEvent: Attempt to fetch the room state")
        room.state { (roomState) in
            guard let roomState = roomState else {
                NSLog("[NotificationService] notificationContentForEvent: Could not fetch the room state")
                onComplete(nil)
                return
            }

            var notificationTitle: String?
            var notificationBody: String?
            
            var threadIdentifier = room.roomId
            let eventSenderName = roomState.members.memberName(event.sender)
            let currentUserId = session.credentials.userId
            
            let pushRule = session.notificationCenter.rule(matching: event, roomState: roomState)
            
            switch event.eventType {
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
                self.sendVoipPush(forEvent: event)
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
                    
                    if !isHighlighted {
                        // Ignore this notif.
                        NSLog("[NotificationService] notificationContentForEvent: Ignore non highlighted notif in mentions only room")
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
                
                let roomDisplayName = session.store.summary?(ofRoom: room.roomId)?.displayname
                let myUserId = session.myUser.userId
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
                        session.crypto.keyVerificationManager.keyVerification(fromKeyVerificationEvent: event,
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
                            NSLog("[NotificationService] notificationContentForEvent: failed to fetch key verification with error: \(error)")
                            onComplete(nil)
                        })
                    } else {
                        // Encrypted messages falls here
                        notificationBody = NSString.localizedUserNotificationString(forKey: "MESSAGE", arguments: [])
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
                        notificationBody = NSString.localizedUserNotificationString(forKey: "MESSAGE", arguments: [])
                        break
                    }
                }
                break
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
            
            guard notificationBody != nil else {
                NSLog("[NotificationService] notificationContentForEvent: notificationBody is nil")
                onComplete(nil)
                return
            }
            
            let notificationContent = self.notificationContent(withTitle: notificationTitle,
                                                               body: notificationBody,
                                                               threadIdentifier: threadIdentifier,
                                                               userId: currentUserId,
                                                               event: event,
                                                               pushRule: pushRule)
            
            NSLog("[NotificationService] notificationContentForEvent: Calling onComplete.")
            onComplete(notificationContent)
        }
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
        
        NSLog("Sound name: \(String(describing: soundName))")
        
        return soundName
    }
    
    func notificationCategoryIdentifier(forEvent event: MXEvent) -> String? {
        let isNotificationContentShown = !event.isEncrypted || self.showDecryptedContentInNotifications
        
        guard isNotificationContentShown else {
            return nil
        }
        
        if event.eventType == .callInvite {
            return Constants.callInviteNotificationCategoryIdentifier
        }
        
        guard event.eventType == .roomMessage || event.eventType == .roomEncrypted else {
            return nil
        }
        
        return "QUICK_REPLY"
    }
    
    /// Attempts to send trigger a VoIP push for the given event
    /// - Parameter event: The call invite event.
    private func sendVoipPush(forEvent event: MXEvent) {
        guard let token = pushNotificationStore.pushKitToken else {
            return
        }
        
        pushNotificationStore.lastCallInvite = event
        
        let appId = BuildSettings.pushKitAppId
        
        pushGatewayRestClient.notifyApp(withId: appId, pushToken: token, eventId: event.eventId, roomId: event.roomId, eventType: nil, sender: event.sender, success: { (rejected) in
            NSLog("[NotificationService] sendVoipPush succeeded, rejected tokens: \(rejected)")
        }) { (error) in
            NSLog("[NotificationService] sendVoipPush failed with error: \(error)")
        }
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
