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
import MatrixSDK

/// The number of milliseconds in one second.
private let MSEC_PER_SEC: TimeInterval = 1000

class NotificationService: UNNotificationServiceExtension {
    
    private struct NSE {
        enum Constants {
            static let voipPushRequestTimeout: TimeInterval = 15
            static let timeNeededToSendVoIPPushes: TimeInterval = 20
        }
    }
    
    //  MARK: - Properties
    
    /// Receiving dates for notifications. Keys are eventId's
    private var receiveDates: [String: Date] = [:]
    
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
    private lazy var mxRestClient: MXRestClient? = {
        guard let userAccount = userAccount else {
            return nil
        }
        return MXRestClient(credentials: userAccount.mxCredentials, unrecognizedCertificateHandler: nil)
    }()
    private static var isLoggerInitialized: Bool = false
    private lazy var pushGatewayRestClient: MXPushGatewayRestClient = {
        let url = URL(string: BuildSettings.serverConfigSygnalAPIUrlString)!
        return MXPushGatewayRestClient(pushGateway: url.scheme! + "://" + url.host!, andOnUnrecognizedCertificateBlock: nil)
    }()
    private var pushNotificationStore: PushNotificationStore = PushNotificationStore()
    private let localAuthenticationService = LocalAuthenticationService(pinCodePreferences: .shared)
    private static let backgroundServiceInitQueue = DispatchQueue(label: "io.element.NotificationService.backgroundServiceInitQueue")
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
        
        MXLog.debug(" ")
        MXLog.debug(" ")
        MXLog.debug("################################################################################")
        MXLog.debug("[NotificationService] Instance: \(self), thread: \(Thread.current)")
        MXLog.debug("[NotificationService] Payload came: \(userInfo)")
        
        //  log memory at the beginning of the process
        logMemory()
        
        UNUserNotificationCenter.current().removeUnwantedNotifications()
        
        //  check if this is a Matrix notification
        guard let roomId = userInfo["room_id"] as? String, let eventId = userInfo["event_id"] as? String else {
            //  it's not a Matrix notification, do not change the content
            MXLog.debug("[NotificationService] didReceiveRequest: This is not a Matrix notification.")
            contentHandler(request.content)
            return
        }
        
        //  save this content as fallback content
        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
            return
        }
        
        //  store receive date
        receiveDates[eventId] = Date()
        
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
        
        MXLog.debug("[NotificationService] serviceExtensionTimeWillExpire")
        //  No-op here. If the process is killed by the OS due to time limit, it will also show the notification with the original content.
    }
    
    deinit {
        MXLog.debug("[NotificationService] deinit for \(self)");
        self.logMemory()
        MXLog.debug(" ")
    }
    
    
    //  MARK: - Private
    
    private func logMemory() {
        MXLog.debug("[NotificationService] Memory: footprint: \(MXMemory.formattedMemoryFootprint()) - available: \(MXMemory.formattedMemoryAvailable())")
    }
    
    private func setupLogger() {
        if !NotificationService.isLoggerInitialized {
            let configuration = MXLogConfiguration()
            configuration.logLevel = .verbose
            configuration.maxLogFilesCount = 100
            configuration.logFilesSizeLimit = 10 * 1024 * 1024; // 10MB
            configuration.subLogName = "nse"
            
            if isatty(STDERR_FILENO) == 0 {
                configuration.redirectLogsToFiles = true
            }
            
            MXLog.configure(configuration)
            
            NotificationService.isLoggerInitialized = true
        }
    }
    
    private func setup(withRoomId roomId: String, eventId: String, completion: @escaping () -> Void) {
        MXKAccountManager.shared()?.forceReloadAccounts()
        self.userAccount = MXKAccountManager.shared()?.activeAccounts.first
        if let userAccount = userAccount {
            Self.backgroundServiceInitQueue.sync {
                if NotificationService.backgroundSyncService?.credentials != userAccount.mxCredentials {
                    MXLog.debug("[NotificationService] setup: MXBackgroundSyncService init: BEFORE")
                    self.logMemory()
                    NotificationService.backgroundSyncService = MXBackgroundSyncService(withCredentials: userAccount.mxCredentials)
                    MXLog.debug("[NotificationService] setup: MXBackgroundSyncService init: AFTER")
                    self.logMemory()
                }
                completion()
            }
        } else {
            MXLog.debug("[NotificationService] setup: No active accounts")
            fallbackToBestAttemptContent(forEventId: eventId)
        }
    }
    
    /// Attempts to preprocess payload and attach room display name to the best attempt content
    /// - Parameters:
    ///   - eventId: Event identifier to mutate best attempt content
    ///   - roomId: Room identifier to fetch display name
    private func preprocessPayload(forEventId eventId: String, roomId: String) {
        if localAuthenticationService.isProtectionSet {
            MXLog.debug("[NotificationService] preprocessPayload: Do not preprocess because app protection is set")
            return
        }
        
        // If a room summary is available, use the displayname for the best attempt title.
        guard let roomSummary = NotificationService.backgroundSyncService.roomSummary(forRoomId: roomId) else { return }
        guard let roomDisplayName = roomSummary.displayname else { return }
        bestAttemptContents[eventId]?.title = roomDisplayName
        
        // At this stage we don't know the message type, so leave the body as set in didReceive.
    }
    
    private func fetchEvent(withEventId eventId: String, roomId: String, allowSync: Bool = true) {
        MXLog.debug("[NotificationService] fetchEvent")
        
        NotificationService.backgroundSyncService.event(withEventId: eventId,
                                                        inRoom: roomId,
                                                        completion: { (response) in
                                                            switch response {
                                                            case .success(let event):
                                                                MXLog.debug("[NotificationService] fetchEvent: Event fetched successfully")
                                                                self.processEvent(event)
                                                            case .failure(let error):
                                                                MXLog.debug("[NotificationService] fetchEvent: error: \(error)")
                                                                self.fallbackToBestAttemptContent(forEventId: eventId)
                                                            }
                                                        })
    }
    
    private func processEvent(_ event: MXEvent) {
        if let receiveDate = receiveDates[event.eventId] {
            MXLog.debug("[NotificationService] processEvent: notification receive delay: \(receiveDate.timeIntervalSince1970*MSEC_PER_SEC - TimeInterval(event.originServerTs)) ms")
        }
        
        guard let content = bestAttemptContents[event.eventId], let userAccount = userAccount else {
            self.fallbackToBestAttemptContent(forEventId: event.eventId)
            return
        }
        
        self.notificationContent(forEvent: event, forAccount: userAccount) { (notificationContent, ignoreBadgeUpdate) in
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
            
            if ignoreBadgeUpdate {
                content.badge = nil
            }
            
            if self.ongoingVoIPPushRequests[event.eventId] == true {
                //  modify the best attempt content, to be able to use in the future
                self.bestAttemptContents[event.eventId] = content
                
                //  There is an ongoing VoIP Push request for this event, wait for it to be completed.
                //  When it completes, it'll continue with the bestAttemptContent.
                return
            } else {
                MXLog.debug("[NotificationService] processEvent: Calling content handler for: \(String(describing: event.eventId)), isUnwanted: \(isUnwantedNotification)")
                self.contentHandlers[event.eventId]?(content)
                //  clear maps
                self.contentHandlers.removeValue(forKey: event.eventId)
                self.bestAttemptContents.removeValue(forKey: event.eventId)
                
                // We are done for this push
                MXLog.debug("--------------------------------------------------------------------------------")
            }
        }
    }
    
    private func fallbackToBestAttemptContent(forEventId eventId: String) {
        MXLog.debug("[NotificationService] fallbackToBestAttemptContent: method called.")
        
        guard let content = bestAttemptContents[eventId] else {
            MXLog.debug("[NotificationService] fallbackToBestAttemptContent: Best attempt content is missing.")
            return
        }
        
        //  call contentHandler
        contentHandlers[eventId]?(content)
        //  clear maps
        contentHandlers.removeValue(forKey: eventId)
        bestAttemptContents.removeValue(forKey: eventId)
        receiveDates.removeValue(forKey: eventId)
        
        // We are done for this push
        MXLog.debug("--------------------------------------------------------------------------------")
    }
    
    private func notificationContent(forEvent event: MXEvent, forAccount account: MXKAccount, onComplete: @escaping (UNNotificationContent?, Bool) -> Void) {
        guard let content = event.content, content.count > 0 else {
            MXLog.debug("[NotificationService] notificationContentForEvent: empty event content")
            onComplete(nil, false)
            return
        }
        
        let roomId = event.roomId!
        let isRoomMentionsOnly = NotificationService.backgroundSyncService.isRoomMentionsOnly(roomId)
        let roomSummary = NotificationService.backgroundSyncService.roomSummary(forRoomId: roomId)
        
        MXLog.debug("[NotificationService] notificationContentForEvent: Attempt to fetch the room state")
        
        self.context(ofEvent: event, inRoom: roomId, completion: { (response) in
            switch response {
                case .success(let (roomState, eventSenderName)):
                    var notificationTitle: String?
                    var notificationBody: String?
                    var additionalUserInfo: [AnyHashable: Any]?
                    var ignoreBadgeUpdate = false
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
                            
                            if let callInviteContent = MXCallInviteEventContent(fromJSON: event.content),
                               callInviteContent.lifetime > event.age,
                               (callInviteContent.lifetime - event.age) > UInt(NSE.Constants.timeNeededToSendVoIPPushes * MSEC_PER_SEC) {
                                NotificationService.backgroundSyncService.roomAccountData(forRoomId: roomId) { response in
                                    if let accountData = response.value, accountData.virtualRoomInfo.isVirtual {
                                        self.sendReadReceipt(forEvent: event)
                                        ignoreBadgeUpdate = true
                                    }
                                    self.validateNotificationContentAndComplete(
                                        notificationTitle: notificationTitle,
                                        notificationBody: notificationBody,
                                        additionalUserInfo: additionalUserInfo,
                                        ignoreBadgeUpdate: ignoreBadgeUpdate,
                                        threadIdentifier: threadIdentifier,
                                        currentUserId: currentUserId,
                                        event: event,
                                        pushRule: pushRule,
                                        onComplete: onComplete
                                    )
                                }
                                self.sendVoipPush(forEvent: event)
                                return
                            } else {
                                MXLog.debug("[NotificationService] notificationContent: Do not attempt to send a VoIP push, there is not enough time to process it.")
                            }
                        case .roomEncrypted:
                            // If unable to decrypt the event, use the fallback.
                            break
                        case .roomMessage:
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
                                    #warning("In practice, this only hides the notification's content. An empty notification may be less useful in this instance?")
                                    // Ignore this notif.
                                    MXLog.debug("[NotificationService] notificationContentForEvent: Ignore non highlighted notif in mentions only room")
                                    onComplete(nil, false)
                                    return
                                }
                            }
                            
                            let msgType = event.content["msgtype"] as? String
                            let messageContent = event.content["body"] as? String
                            let isReply = event.isReply()
                            
                            if isReply {
                                notificationTitle = self.replyTitle(for: eventSenderName, in: roomDisplayName)
                            } else {
                                notificationTitle = self.messageTitle(for: eventSenderName, in: roomDisplayName)
                            }
                            
                            if event.isEncrypted && !self.showDecryptedContentInNotifications {
                                // Hide the content
                                notificationBody = NSString.localizedUserNotificationString(forKey: "MESSAGE", arguments: [])
                                break
                            }
                            
                            switch msgType {
                            case kMXMessageTypeEmote:
                                notificationBody = NSString.localizedUserNotificationString(forKey: "ACTION_FROM_USER", arguments: [eventSenderName, messageContent as Any])
                            case kMXMessageTypeImage:
                                notificationBody = NSString.localizedUserNotificationString(forKey: "PICTURE_FROM_USER", arguments: [eventSenderName])
                            case kMXMessageTypeVideo:
                                notificationBody = NSString.localizedUserNotificationString(forKey: "VIDEO_FROM_USER", arguments: [eventSenderName])
                            case kMXMessageTypeAudio:
                                if event.isVoiceMessage() {
                                    notificationBody = NSString.localizedUserNotificationString(forKey: "VOICE_MESSAGE_FROM_USER", arguments: [eventSenderName])
                                } else {
                                    notificationBody = NSString.localizedUserNotificationString(forKey: "AUDIO_FROM_USER", arguments: [eventSenderName, messageContent as Any])
                                }
                            case kMXMessageTypeFile:
                                notificationBody = NSString.localizedUserNotificationString(forKey: "FILE_FROM_USER", arguments: [eventSenderName, messageContent as Any])
                            
                            // All other message types such as text, notice, server notice etc
                            default:
                                if event.isReply() {
                                    let parser = MXReplyEventParser()
                                    let replyParts = parser.parse(event)
                                    notificationBody = replyParts.bodyParts.replyText
                                } else {
                                    notificationBody = messageContent
                                }
                            }
                        case .roomMember:
                            // If the current user is already joined, display updated displayname/avatar events.
                            // This is an unexpected path, but has been seen in some circumstances.
                            if NotificationService.backgroundSyncService.roomSummary(forRoomId: roomId)?.membership == .join {
                                notificationTitle = self.messageTitle(for: eventSenderName, in: roomDisplayName)
                                
                                // If the sender's membership is join and hasn't changed.
                                if let newContent = MXRoomMemberEventContent(fromJSON: event.content),
                                   let prevContentDict = event.prevContent,
                                   let oldContent = MXRoomMemberEventContent(fromJSON: prevContentDict),
                                   newContent.membership == kMXMembershipStringJoin,
                                   oldContent.membership == kMXMembershipStringJoin {
                                    
                                    // Check for display name changes
                                    if newContent.displayname != oldContent.displayname {
                                        // If there was a change, use the sender's userID if one was blank and show the change.
                                        if let oldDisplayname = oldContent.displayname ?? event.sender,
                                           let displayname = newContent.displayname ?? event.sender {
                                            notificationBody = NSString.localizedUserNotificationString(forKey: "USER_UPDATED_DISPLAYNAME", arguments: [oldDisplayname, displayname])
                                        } else {
                                            // Should never be reached as the event should always have a sender.
                                            notificationBody = NSString.localizedUserNotificationString(forKey: "GENERIC_USER_UPDATED_DISPLAYNAME", arguments: [eventSenderName])
                                        }
                                    } else {
                                        // If the display name hasn't changed, handle as an avatar change.
                                        notificationBody = NSString.localizedUserNotificationString(forKey: "USER_UPDATED_AVATAR", arguments: [eventSenderName])
                                    }
                                } else {
                                    // No known reports of having reached this situation for a membership notification
                                    // So use a generic membership updated fallback.
                                    notificationBody = NSString.localizedUserNotificationString(forKey: "USER_MEMBERSHIP_UPDATED", arguments: [eventSenderName])
                                }
                            // Otherwise treat the notification as an invite.
                            // This is the expected notification content for a membership event.
                            } else {
                                if roomDisplayName != nil && roomDisplayName != eventSenderName {
                                    notificationBody = NSString.localizedUserNotificationString(forKey: "USER_INVITE_TO_NAMED_ROOM", arguments: [eventSenderName, roomDisplayName as Any])
                                } else {
                                    notificationBody = NSString.localizedUserNotificationString(forKey: "USER_INVITE_TO_CHAT", arguments: [eventSenderName])
                                }
                            }
                            
                        case .sticker:
                            notificationTitle = self.messageTitle(for: eventSenderName, in: roomDisplayName)
                            notificationBody = NSString.localizedUserNotificationString(forKey: "STICKER_FROM_USER", arguments: [eventSenderName as Any])
                        
                        // Reactions are unexpected notification types, but have been seen in some circumstances.
                        case .reaction:
                            notificationTitle = self.messageTitle(for: eventSenderName, in: roomDisplayName)
                            if let reactionKey = event.relatesTo?.key {
                                // Try to show the reaction key in the notification.
                                notificationBody = NSString.localizedUserNotificationString(forKey: "REACTION_FROM_USER", arguments: [eventSenderName, reactionKey])
                            } else {
                                // Otherwise show a generic reaction.
                                notificationBody = NSString.localizedUserNotificationString(forKey: "GENERIC_REACTION_FROM_USER", arguments: [eventSenderName])
                            }
                            
                        case .custom:
                            if (event.type == kWidgetMatrixEventTypeString || event.type == kWidgetModularEventTypeString),
                               let type = event.content?["type"] as? String,
                               (type == kWidgetTypeJitsiV1 || type == kWidgetTypeJitsiV2) {
                                notificationBody = NSString.localizedUserNotificationString(forKey: "GROUP_CALL_STARTED", arguments: nil)
                                notificationTitle = roomDisplayName
                                
                                // call notifications should stand out from normal messages, so we don't stack them
                                threadIdentifier = nil
                                //  only send VoIP pushes if ringing is enabled for group calls
                                if RiotSettings.shared.enableRingingForGroupCalls {
                                    self.sendVoipPush(forEvent: event)
                                } else {
                                    additionalUserInfo = [Constants.userInfoKeyPresentNotificationOnForeground: true]
                                }
                            }
                        case .pollStart:
                            notificationTitle = self.messageTitle(for: eventSenderName, in: roomDisplayName)
                            notificationBody = MXEventContentPollStart(fromJSON: event.content)?.question
                        default:
                            break
                    }
                    
                    
                    self.validateNotificationContentAndComplete(
                        notificationTitle: notificationTitle,
                        notificationBody: notificationBody,
                        additionalUserInfo: additionalUserInfo,
                        ignoreBadgeUpdate: ignoreBadgeUpdate,
                        threadIdentifier: threadIdentifier,
                        currentUserId: currentUserId,
                        event: event,
                        pushRule: pushRule,
                        onComplete: onComplete
                    )
                case .failure(let error):
                    MXLog.debug("[NotificationService] notificationContentForEvent: error: \(error)")
                    onComplete(nil, false)
            }
        })
    }
    
    private func validateNotificationContentAndComplete(
        notificationTitle: String?,
        notificationBody: String?,
        additionalUserInfo: [AnyHashable: Any]?,
        ignoreBadgeUpdate: Bool,
        threadIdentifier: String?,
        currentUserId: String?,
        event: MXEvent,
        pushRule: MXPushRule?,
        onComplete: @escaping (UNNotificationContent?, Bool) -> Void
    ) {
        
        var validatedNotificationBody: String? = notificationBody
        var validatedNotificationTitle: String? = notificationTitle
        if self.localAuthenticationService.isProtectionSet {
            MXLog.debug("[NotificationService] validateNotificationContentAndComplete: Resetting title and body because app protection is set")
            validatedNotificationBody = NSString.localizedUserNotificationString(forKey: "MESSAGE_PROTECTED", arguments: [])
            validatedNotificationTitle = nil
        }
        
        guard validatedNotificationBody != nil else {
            MXLog.debug("[NotificationService] validateNotificationContentAndComplete: notificationBody is nil")
            onComplete(nil, false)
            return
        }
        
        let notificationContent = self.notificationContent(withTitle: validatedNotificationTitle,
                                                           body: validatedNotificationBody,
                                                           threadIdentifier: threadIdentifier,
                                                           userId: currentUserId,
                                                           event: event,
                                                           pushRule: pushRule,
                                                           additionalInfo: additionalUserInfo)
        
        MXLog.debug("[NotificationService] validateNotificationContentAndComplete: Calling onComplete.")
        onComplete(notificationContent, ignoreBadgeUpdate)
    }
    
    /// Returns the default title for message notifications.
    /// - Parameters:
    ///   - eventSenderName: The displayname of the sender.
    ///   - roomDisplayName: The displayname of the room the message was sent in.
    /// - Returns: A string to be used for the notification's title.
    private func messageTitle(for eventSenderName: String, in roomDisplayName: String?) -> String {
        // Display the room name only if it is different than the sender name
        if let roomDisplayName = roomDisplayName, roomDisplayName != eventSenderName {
            return NSString.localizedUserNotificationString(forKey: "MSG_FROM_USER_IN_ROOM_TITLE", arguments: [eventSenderName, roomDisplayName])
        } else {
            return eventSenderName
        }
    }
    
    private func replyTitle(for eventSenderName: String, in roomDisplayName: String?) -> String {
        // Display the room name only if it is different than the sender name
        if let roomDisplayName = roomDisplayName, roomDisplayName != eventSenderName {
            return NSString.localizedUserNotificationString(forKey: "REPLY_FROM_USER_IN_ROOM_TITLE", arguments: [eventSenderName, roomDisplayName])
        } else {
            return NSString.localizedUserNotificationString(forKey: "REPLY_FROM_USER_TITLE", arguments: [eventSenderName])
        }
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
                                     pushRule: MXPushRule?,
                                     additionalInfo: [AnyHashable: Any]? = nil) -> UNNotificationContent {
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
        notificationContent.userInfo = notificationUserInfo(forEvent: event,
                                                            andUserId: userId,
                                                            additionalInfo: additionalInfo)
        
        return notificationContent
    }
    
    private func notificationUserInfo(forEvent event: MXEvent,
                                      andUserId userId: String?,
                                      additionalInfo: [AnyHashable: Any]? = nil) -> [AnyHashable: Any] {
        var notificationUserInfo: [AnyHashable: Any] = [
            "type": "full",
            "room_id": event.roomId as Any,
            "event_id": event.eventId as Any
        ]
        if let userId = userId {
            notificationUserInfo["user_id"] = userId
        }
        if let additionalInfo = additionalInfo {
            for (key, value) in additionalInfo {
                notificationUserInfo[key] = value
            }
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
        
        MXLog.debug("Sound name: \(String(describing: soundName))")
        
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
        
        if #available(iOS 13.0, *) {
            if event.isEncrypted {
                guard let clearEvent = event.clear else {
                    MXLog.debug("[NotificationService] sendVoipPush: Do not send a VoIP push for undecrypted event, it'll cause a crash.")
                    return
                }
                
                //  Add some original data on the clear event
                clearEvent.eventId = event.eventId
                clearEvent.originServerTs = event.originServerTs
                clearEvent.sender = event.sender
                clearEvent.roomId = event.roomId
                pushNotificationStore.storeCallInvite(clearEvent)
            } else {
                pushNotificationStore.storeCallInvite(event)
            }
        }
        
        ongoingVoIPPushRequests[event.eventId] = true
        
        let appId = BuildSettings.pushKitAppId
        
        pushGatewayRestClient.notifyApp(withId: appId,
                                        pushToken: token,
                                        eventId: event.eventId,
                                        roomId: event.roomId,
                                        eventType: nil,
                                        sender: event.sender,
                                        timeout: NSE.Constants.voipPushRequestTimeout,
                                        success: { [weak self] (rejected) in
                                            MXLog.debug("[NotificationService] sendVoipPush succeeded, rejected tokens: \(rejected)")
                                            
                                            guard let self = self else { return }
                                            self.ongoingVoIPPushRequests.removeValue(forKey: event.eventId)
                                            
                                            self.fallbackToBestAttemptContent(forEventId: event.eventId)
                                        }) { [weak self] (error) in
            MXLog.debug("[NotificationService] sendVoipPush failed with error: \(error)")
            
            guard let self = self else { return }
            self.ongoingVoIPPushRequests.removeValue(forKey: event.eventId)
            
            self.fallbackToBestAttemptContent(forEventId: event.eventId)
        }
    }
    
    private func sendReadReceipt(forEvent event: MXEvent) {
        guard let mxRestClient = mxRestClient else {
            MXLog.error("[NotificationService] sendReadReceipt: Missing mxRestClient for read receipt request.")
            return
        }
        guard let eventId = event.eventId,
              let roomId = event.roomId else {
            MXLog.error("[NotificationService] sendReadReceipt: Event information missing for read receipt request.")
            return
        }
        
        mxRestClient.sendReadReceipt(toRoom: roomId, forEvent: eventId) { response in
            if response.isSuccess {
                MXLog.debug("[NotificationService] sendReadReceipt: Read receipt send successfully.")
            } else if let error = response.error {
                MXLog.error("[NotificationService] sendReadReceipt: Read receipt send failed with error \(error).")
            }
        }
    }
}
