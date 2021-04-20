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
    
    //  MARK: - Properties
    
    /// Content handlers. Keys are eventId's
    private var contentHandlers: [String: ((UNNotificationContent) -> Void)] = [:]
    
    /// Flags to indicate there is an ongoing VoIP Push request for events. Keys are eventId's
    private var ongoingVoIPPushRequests: [String: Bool] = [:]
    
    private var userAccount: MXKAccount?
    
    /// Best attempt contents. Will be updated incrementally, if something fails during the process, this best attempt content will be showed as notification. Keys are eventId's
    private var bestAttemptContents: [String: UNMutableNotificationContent] = [:]
    
    private static var backgroundSyncService: MXBackgroundSyncService!
    private var showDecryptedContentInNotifications: Bool {
        return RiotSettings.shared.showDecryptedContentInNotifications
    }
    private lazy var configuration: Configurable = {
        return CommonConfiguration()
    }()
    private static var isLoggerInitialized: Bool = false
    private lazy var pushGatewayRestClient: MXPushGatewayRestClient = {
        let url = URL(string: BuildSettings.serverConfigSygnalAPIUrlString)!
        return MXPushGatewayRestClient(pushGateway: url.scheme! + "://" + url.host!, andOnUnrecognizedCertificateBlock: nil)
    }()
    private var pushNotificationStore: PushNotificationStore = PushNotificationStore()
    private let localAuthenticationService = LocalAuthenticationService(pinCodePreferences: .shared)
    
    //  MARK: - Method Overrides
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        let userInfo = request.content.userInfo

        // Set static application settings
        configuration.setupSettings()
        
        if DataProtectionHelper.isDeviceInRebootedAndLockedState(appGroupIdentifier: MXSDKOptions.sharedInstance().applicationGroupIdentifier) {
            //  kill the process in this state, this leads for the notification to be displayed as came from APNS
            exit(0)
        }
        
        //  setup logs
        setupLogger()
        
        NSLog(" ")
        NSLog(" ")
        NSLog("################################################################################")
        NSLog("[NotificationService] Instance: \(self), thread: \(Thread.current)")
        NSLog("[NotificationService] Payload came: \(userInfo)")
        
        //  log memory at the beginning of the process
        logMemory()
        
        UNUserNotificationCenter.current().removeUnwantedNotifications()
        
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
    
    deinit {
        NSLog("[NotificationService] deinit for \(self)");
        self.logMemory()
        NSLog(" ")
    }
    
    
    //  MARK: - Private
    
    private func logMemory() {
        NSLog("[NotificationService] Memory: footprint: \(MXMemory.formattedMemoryFootprint()) - available: \(MXMemory.formattedMemoryAvailable())")
    }
    
    private func setupLogger() {
        if !NotificationService.isLoggerInitialized {
            if isatty(STDERR_FILENO) == 0 {
                MXLogger.setSubLogName("nse")
                let sizeLimit: UInt = 10 * 1024 * 1024; // 10MB
                MXLogger.redirectNSLog(toFiles: true, numberOfFiles: 100, sizeLimit: sizeLimit)
            }
            NotificationService.isLoggerInitialized = true
        }
    }
    
    private func setup(withRoomId roomId: String, eventId: String, completion: @escaping () -> Void) {
        MXKAccountManager.shared()?.forceReloadAccounts()
        self.userAccount = MXKAccountManager.shared()?.activeAccounts.first
        if let userAccount = userAccount {
            if NotificationService.backgroundSyncService == nil {
                NSLog("[NotificationService] setup: MXBackgroundSyncService init: BEFORE")
                self.logMemory()
                NotificationService.backgroundSyncService = MXBackgroundSyncService(withCredentials: userAccount.mxCredentials)
                NSLog("[NotificationService] setup: MXBackgroundSyncService init: AFTER")
                self.logMemory()
            }
            completion()
        } else {
            NSLog("[NotificationService] setup: No active accounts")
            fallbackToBestAttemptContent(forEventId: eventId)
        }
    }
    
    /// Attempts to preprocess payload and attach room display name to the best attempt content
    /// - Parameters:
    ///   - eventId: Event identifier to mutate best attempt content
    ///   - roomId: Room identifier to fetch display name
    private func preprocessPayload(forEventId eventId: String, roomId: String) {
        if localAuthenticationService.isProtectionSet {
            NSLog("[NotificationService] preprocessPayload: Do not preprocess because app protection is set")
            return
        }
        guard let roomSummary = NotificationService.backgroundSyncService.roomSummary(forRoomId: roomId) else { return }
        guard let roomDisplayName = roomSummary.displayname else { return }
        if roomSummary.isDirect == true {
            bestAttemptContents[eventId]?.body = NSString.localizedUserNotificationString(forKey: "MESSAGE_FROM_X", arguments: [roomDisplayName as Any])
        } else {
            bestAttemptContents[eventId]?.body = NSString.localizedUserNotificationString(forKey: "MESSAGE_IN_X", arguments: [roomDisplayName as Any])
        }
    }
    
    private func fetchEvent(withEventId eventId: String, roomId: String, allowSync: Bool = true) {
        NSLog("[NotificationService] fetchEvent")
        
        NotificationService.backgroundSyncService.event(withEventId: eventId,
                                                        inRoom: roomId,
                                                        completion: { (response) in
                                                            switch response {
                                                            case .success(let event):
                                                                NSLog("[NotificationService] fetchEvent: Event fetched successfully")
                                                                self.processEvent(event)
                                                            case .failure(let error):
                                                                NSLog("[NotificationService] fetchEvent: error: \(error)")
                                                                self.fallbackToBestAttemptContent(forEventId: eventId)
                                                            }
                                                        })
    }
    
    private func processEvent(_ event: MXEvent) {
        guard let content = bestAttemptContents[event.eventId], let userAccount = userAccount else {
            self.fallbackToBestAttemptContent(forEventId: event.eventId)
            return
        }
        
        self.notificationContent(forEvent: event, forAccount: userAccount) { (notificationContent) in
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
            
            //  modify the best attempt content, to be able to use in future
            self.bestAttemptContents[event.eventId] = content
            
            if self.ongoingVoIPPushRequests[event.eventId] == true {
                //  There is an ongoing VoIP Push request for this event, wait for it to be completed.
                //  When it completes, it'll continue with the bestAttemptContent.
                return
            } else {
                NSLog("[NotificationService] processEvent: Calling content handler for: \(String(describing: event.eventId)), isUnwanted: \(isUnwantedNotification)")
                self.contentHandlers[event.eventId]?(content)
                //  clear maps
                self.contentHandlers.removeValue(forKey: event.eventId)
                self.bestAttemptContents.removeValue(forKey: event.eventId)
                
                // We are done for this push
                NSLog("--------------------------------------------------------------------------------")
            }
        }
    }
    
    private func fallbackToBestAttemptContent(forEventId eventId: String) {
        NSLog("[NotificationService] fallbackToBestAttemptContent: method called.")
        
        guard let content = bestAttemptContents[eventId] else {
            NSLog("[NotificationService] fallbackToBestAttemptContent: Best attempt content is missing.")
            return
        }
        
        //  call contentHandler
        contentHandlers[eventId]?(content)
        //  clear maps
        contentHandlers.removeValue(forKey: eventId)
        bestAttemptContents.removeValue(forKey: eventId)
        
        // We are done for this push
        NSLog("--------------------------------------------------------------------------------")
    }
    
    private func notificationContent(forEvent event: MXEvent, forAccount account: MXKAccount, onComplete: @escaping (UNNotificationContent?) -> Void) {
        guard let content = event.content, content.count > 0 else {
            NSLog("[NotificationService] notificationContentForEvent: empty event content")
            onComplete(nil)
            return
        }
        
        let roomId = event.roomId!
        let isRoomMentionsOnly = NotificationService.backgroundSyncService.isRoomMentionsOnly(roomId)
        let roomSummary = NotificationService.backgroundSyncService.roomSummary(forRoomId: roomId)
        
        NSLog("[NotificationService] notificationContentForEvent: Attempt to fetch the room state")
        
        self.context(ofEvent: event, inRoom: roomId, completion: { (response) in
            switch response {
                case .success(let (roomState, eventSenderName)):
                    var notificationTitle: String?
                    var notificationBody: String?
                    
                    var threadIdentifier: String? = roomId
                    let currentUserId = account.mxCredentials.userId
                    let roomDisplayName = roomSummary?.displayname
                    let pushRule = NotificationService.backgroundSyncService.pushRule(matching: event, roomState: roomState)
                    
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
                            if isRoomMentionsOnly {
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
                            
                            // Display the room name only if it is different than the sender name
                            if roomDisplayName != nil && roomDisplayName != eventSenderName {
                                notificationTitle = NSString.localizedUserNotificationString(forKey: "MSG_FROM_USER_IN_ROOM_TITLE", arguments: [eventSenderName as Any, roomDisplayName as Any])
                                
                                if msgType == kMXMessageTypeText {
                                    notificationBody = messageContent
                                } else if msgType == kMXMessageTypeEmote {
                                    notificationBody = NSString.localizedUserNotificationString(forKey: "ACTION_FROM_USER", arguments: [eventSenderName as Any, messageContent as Any])
                                } else if msgType == kMXMessageTypeImage {
                                    notificationBody = NSString.localizedUserNotificationString(forKey: "IMAGE_FROM_USER", arguments: [eventSenderName as Any, messageContent as Any])
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
                            if roomDisplayName != nil && roomDisplayName != eventSenderName {
                                notificationBody = NSString.localizedUserNotificationString(forKey: "USER_INVITE_TO_NAMED_ROOM", arguments: [eventSenderName as Any, roomDisplayName as Any])
                            } else {
                                notificationBody = NSString.localizedUserNotificationString(forKey: "USER_INVITE_TO_CHAT", arguments: [eventSenderName as Any])
                            }
                        case .sticker:
                            if roomDisplayName != nil && roomDisplayName != eventSenderName {
                                notificationTitle = NSString.localizedUserNotificationString(forKey: "MSG_FROM_USER_IN_ROOM_TITLE", arguments: [eventSenderName as Any, roomDisplayName as Any])
                            } else {
                                notificationTitle = eventSenderName
                            }
                            
                            notificationBody = NSString.localizedUserNotificationString(forKey: "STICKER_FROM_USER", arguments: [eventSenderName as Any])
                        default:
                            break
                    }
                    
                    if self.localAuthenticationService.isProtectionSet {
                        NSLog("[NotificationService] notificationContentForEvent: Resetting title and body because app protection is set")
                        notificationBody = NSString.localizedUserNotificationString(forKey: "MESSAGE_PROTECTED", arguments: [])
                        notificationTitle = nil
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
                case .failure(let error):
                    NSLog("[NotificationService] notificationContentForEvent: error: \(error)")
                    onComplete(nil)
            }
        })
    }
    
    /// Get the context of an event.
    /// - Parameters:
    ///   - event: the event
    ///   - roomId: the id of the room of the event.
    ///   - completion: Completion block that will return the room state and the sender display name.
    private func context(ofEvent event: MXEvent, inRoom roomId: String,
                    completion: @escaping (MXResponse<(MXRoomState, String)>) -> Void) {
        // First get the room state
        NotificationService.backgroundSyncService.roomState(forRoomId: roomId) { (response) in
            switch response {
                case .success(let roomState):
                    // Extract the member name from room state member
                    let eventSender = event.sender!
                    let eventSenderName = roomState.members.memberName(eventSender) ?? eventSender
                    
                    // Check if we are happy with it
                    if eventSenderName != eventSender
                        || roomState.members.member(withUserId: eventSender) != nil {
                        completion(.success((roomState, eventSenderName)))
                        return
                    }
                    
                    // Else, if the room member is not known, use the user profile to avoid to display a Matrix id
                    NotificationService.backgroundSyncService.profile(ofMember: eventSender, inRoom: roomId) { (response) in
                        switch response {
                            case .success((let displayName, _)):
                                guard let displayName = displayName else {
                                    completion(.success((roomState, eventSender)))
                                    return
                                }
                                completion(.success((roomState, displayName)))

                            case .failure(_):
                                completion(.success((roomState, eventSender)))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }
    
    private func notificationContent(withTitle title: String?,
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
    
    private func notificationUserInfo(forEvent event: MXEvent, andUserId userId: String?) -> [AnyHashable: Any] {
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
    
    private func notificationSoundName(fromPushRule pushRule: MXPushRule?) -> String? {
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
    
    private func notificationCategoryIdentifier(forEvent event: MXEvent) -> String? {
        let isNotificationContentShown = (!event.isEncrypted || self.showDecryptedContentInNotifications)
            && !localAuthenticationService.isProtectionSet
        
        guard isNotificationContentShown else {
            return Constants.toBeRemovedNotificationCategoryIdentifier
        }
        
        if event.eventType == .callInvite {
            return Constants.callInviteNotificationCategoryIdentifier
        }
        
        guard event.eventType == .roomMessage || event.eventType == .roomEncrypted else {
            return Constants.toBeRemovedNotificationCategoryIdentifier
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
        
        ongoingVoIPPushRequests[event.eventId] = true
        
        let appId = BuildSettings.pushKitAppId
        
        pushGatewayRestClient.notifyApp(withId: appId, pushToken: token, eventId: event.eventId, roomId: event.roomId, eventType: nil, sender: event.sender, success: { [weak self] (rejected) in
            NSLog("[NotificationService] sendVoipPush succeeded, rejected tokens: \(rejected)")
            
            guard let self = self else { return }
            self.ongoingVoIPPushRequests.removeValue(forKey: event.eventId)
            
            self.fallbackToBestAttemptContent(forEventId: event.eventId)
        }) { [weak self] (error) in
            NSLog("[NotificationService] sendVoipPush failed with error: \(error)")
            
            guard let self = self else { return }
            self.ongoingVoIPPushRequests.removeValue(forKey: event.eventId)
            
            self.fallbackToBestAttemptContent(forEventId: event.eventId)
        }
    }
    
}
