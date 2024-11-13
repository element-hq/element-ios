/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
        let restClient = MXRestClient(credentials: userAccount.mxCredentials, unrecognizedCertificateHandler: nil, persistentTokenDataHandler: { persistTokenDataHandler in
            MXKAccountManager.shared().readAndWriteCredentials(persistTokenDataHandler)
        }, unauthenticatedHandler: { error, softLogout, refreshTokenAuth, completion in
            userAccount.handleUnauthenticatedWithError(error, isSoftLogout: softLogout, isRefreshTokenAuth: refreshTokenAuth, andCompletion: completion)
        })
        return restClient
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
    
    override init() {
        super.init()
        
        // Set up runtime language and fallback by considering the userDefaults object shared within the application group.
        let sharedUserDefaults = MXKAppSettings.standard().sharedUserDefaults
        if let language = sharedUserDefaults?.string(forKey: "appLanguage") {
            Bundle.mxk_setLanguage(language)
        }
        Bundle.mxk_setFallbackLanguage("en")
    }
    
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
        
        setupAnalytics()
        
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
            self.fetchAndProcessEvent(withEventId: eventId, roomId: roomId)
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
    
    private func setupAnalytics(){
        // Configure our analytics. It will start if the option is enabled
        let analytics = Analytics.shared
        MXSDKOptions.sharedInstance().analyticsDelegate = analytics
        analytics.startIfEnabled()
    }
    
    private func setup(withRoomId roomId: String, eventId: String, completion: @escaping () -> Void) {
        MXKAccountManager.sharedManager(withReload: true)
        self.userAccount = MXKAccountManager.shared()?.activeAccounts.first
        if let userAccount = userAccount {
            Self.backgroundServiceInitQueue.sync {
                if NotificationService.backgroundSyncService?.credentials != userAccount.mxCredentials {
                    MXLog.debug("[NotificationService] setup: MXBackgroundSyncService init: BEFORE")
                    self.logMemory()
                    
                    NotificationService.backgroundSyncService = MXBackgroundSyncService(
                        withCredentials: userAccount.mxCredentials,
                        persistTokenDataHandler: { persistTokenDataHandler in
                            MXKAccountManager.shared().readAndWriteCredentials(persistTokenDataHandler)
                        }, unauthenticatedHandler: { error, softLogout, refreshTokenAuth, completion in
                            userAccount.handleUnauthenticatedWithError(error, isSoftLogout: softLogout, isRefreshTokenAuth: refreshTokenAuth, andCompletion: completion)
                        })
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
        guard let roomDisplayName = roomSummary.displayName else { return }
        bestAttemptContents[eventId]?.title = roomDisplayName
        
        // At this stage we don't know the message type, so leave the body as set in didReceive.
    }
    
    private func fetchAndProcessEvent(withEventId eventId: String, roomId: String) {
        MXLog.debug("[NotificationService] fetchAndProcessEvent")
                
        NotificationService.backgroundSyncService.event(withEventId: eventId, inRoom: roomId) { [weak self] (response) in
            switch response {
            case .success(let event):
                MXLog.debug("[NotificationService] fetchAndProcessEvent: Event fetched successfully")
                self?.checkPlaybackAndContinueProcessing(event, roomId: roomId)
            case .failure(let error):
                MXLog.error("[NotificationService] fetchAndProcessEvent: Failed fetching notification event", context: error)
                self?.fallbackToBestAttemptContent(forEventId: eventId)
            }
        }
    }
    
    private func checkPlaybackAndContinueProcessing(_ notificationEvent: MXEvent, roomId: String) {
        NotificationService.backgroundSyncService.readMarkerEvent(forRoomId: roomId) { [weak self] response in
            switch response {
            case .success(let readMarkerEvent):
                MXLog.debug("[NotificationService] checkPlaybackAndContinueProcessing: Read marker event fetched successfully")
                
                // As origin server timestamps are not always correct data in a federated environment, we add 10 minutes
                // to the calculation to reduce the possibility that an event is marked as read which isn't.
                let notificationTimestamp = notificationEvent.originServerTs + (10 * 60 * 1000)
                
                if readMarkerEvent.originServerTs > notificationTimestamp {
                    MXLog.error("[NotificationService] checkPlaybackAndContinueProcessing: Event already read, discarding.")
                    self?.discardEvent(event: notificationEvent)
                } else {
                    self?.processEvent(notificationEvent)
                }
                
            case .failure(let error):
                MXLog.error("[NotificationService] checkPlaybackAndContinueProcessing: Failed fetching read marker event", context: error)
                self?.processEvent(notificationEvent)
            }
        }
    }
    
    private func processEvent(_ event: MXEvent) {
        if let receiveDate = receiveDates[event.eventId] {
            MXLog.debug("[NotificationService] processEvent: notification receive delay: \(receiveDate.timeIntervalSince1970*MSEC_PER_SEC - TimeInterval(event.originServerTs)) ms")
        }
        
        guard let content = bestAttemptContents[event.eventId], let userAccount = userAccount else {
            self.fallbackToBestAttemptContent(forEventId: event.eventId)
            return
        }
        
        self.notificationContent(forEvent: event, forAccount: userAccount) { [weak self] (notificationContent, ignoreBadgeUpdate) in
            guard let self = self else { return }
            
            guard let newContent = notificationContent else {
                // We still want them removed if the NSE filtering entitlement is not available
                content.categoryIdentifier = Constants.toBeRemovedNotificationCategoryIdentifier
                self.discardEvent(event: event)
                return
            }
            
            content.title = newContent.title
            content.subtitle = newContent.subtitle
            content.body = newContent.body
            content.threadIdentifier = newContent.threadIdentifier
            content.categoryIdentifier = newContent.categoryIdentifier
            content.userInfo = newContent.userInfo
            content.sound = newContent.sound
            
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
                self.finishProcessing(forEventId: event.eventId, withContent: content)
            }
        }
    }
    
    private func discardEvent(event:MXEvent) {
        MXLog.debug("[NotificationService] discardEvent: Discarding event: \(String(describing: event.eventId))")
        finishProcessing(forEventId: event.eventId, withContent: UNNotificationContent())
    }
    
    private func fallbackToBestAttemptContent(forEventId eventId: String) {
        MXLog.debug("[NotificationService] fallbackToBestAttemptContent: method called.")
        
        guard let content = bestAttemptContents[eventId] else {
            MXLog.debug("[NotificationService] fallbackToBestAttemptContent: Best attempt content is missing.")
            return
        }
        
        finishProcessing(forEventId: eventId, withContent: content)
    }
    
    private func finishProcessing(forEventId eventId: String, withContent content: UNNotificationContent) {
        MXLog.debug("[NotificationService] finishProcessingEvent: Calling content handler for: \(String(describing: eventId))")
        
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
                    let roomDisplayName = roomSummary?.displayName
                    let pushRule = NotificationService.backgroundSyncService.pushRule(matching: event, roomState: roomState)
                
                    // if the push rule must not be notified we complete and return
                    if pushRule?.dontNotify == true {
                        onComplete(nil, false)
                        return
                    }

                    switch event.eventType {
                        case .callInvite:
                            let offer = event.content["offer"] as? [AnyHashable: Any]
                            let sdp = offer?["sdp"] as? String
                            let isVideoCall = sdp?.contains("m=video") ?? false
                            
                            if isVideoCall {
                                notificationBody = NotificationService.localizedString(forKey: "VIDEO_CALL_FROM_USER", eventSenderName)
                            } else {
                                notificationBody = NotificationService.localizedString(forKey: "VOICE_CALL_FROM_USER", eventSenderName)
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
                                    // In practice, this only hides the notification's content. An empty notification may be less useful in this instance?
                                    // Ignore this notif.
                                    MXLog.debug("[NotificationService] notificationContentForEvent: Ignore non highlighted notif in mentions only room")
                                    onComplete(nil, false)
                                    return
                                }
                            }
                            
                            let msgType = event.content[kMXMessageTypeKey] as? String
                            let messageContent = event.content[kMXMessageBodyKey] as? String ?? ""
                            let isReply = event.isReply()
                            
                            if isReply {
                                notificationTitle = self.replyTitle(for: eventSenderName, in: roomDisplayName)
                            } else {
                                notificationTitle = self.messageTitle(for: eventSenderName, in: roomDisplayName)
                            }
                            
                            if event.isEncrypted && !self.showDecryptedContentInNotifications {
                                // Hide the content
                                notificationBody = NotificationService.localizedString(forKey: "MESSAGE")
                                break
                            }
                            
                            if event.location != nil {
                                notificationBody = NotificationService.localizedString(forKey: "LOCATION_FROM_USER", eventSenderName)
                                break
                            }
                            
                            switch msgType {
                            case kMXMessageTypeEmote:
                                notificationBody = NotificationService.localizedString(forKey: "ACTION_FROM_USER", eventSenderName, messageContent)
                            case kMXMessageTypeImage:
                                notificationBody = NotificationService.localizedString(forKey: "PICTURE_FROM_USER", eventSenderName)
                            case kMXMessageTypeVideo:
                                notificationBody = NotificationService.localizedString(forKey: "VIDEO_FROM_USER", eventSenderName)
                            case kMXMessageTypeAudio:
                                if event.isVoiceMessage() {
                                    // Ignore voice broadcast chunk event except the first one.
                                    if let chunkInfo = event.content[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkType] as? [String: UInt] {
                                        if chunkInfo[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkSequence] == 1 {
                                            notificationBody = NotificationService.localizedString(forKey: "VOICE_BROADCAST_FROM_USER", eventSenderName)
                                        }
                                    } else {
                                        notificationBody = NotificationService.localizedString(forKey: "VOICE_MESSAGE_FROM_USER", eventSenderName)
                                    }
                                } else {
                                    notificationBody = NotificationService.localizedString(forKey: "AUDIO_FROM_USER", eventSenderName, messageContent)
                                }
                            case kMXMessageTypeFile:
                                notificationBody = NotificationService.localizedString(forKey: "FILE_FROM_USER", eventSenderName, messageContent)
                            
                            // All other message types such as text, notice, server notice etc
                            default:
                                if event.isReply() {
                                    let parser = MXReplyEventParser()
                                    let replyParts = parser.parse(event)
                                    notificationBody = replyParts?.bodyParts.replyText
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
                                            notificationBody = NotificationService.localizedString(forKey: "USER_UPDATED_DISPLAYNAME", oldDisplayname, displayname)
                                        } else {
                                            // Should never be reached as the event should always have a sender.
                                            notificationBody = NotificationService.localizedString(forKey: "GENERIC_USER_UPDATED_DISPLAYNAME", eventSenderName)
                                        }
                                    } else {
                                        // If the display name hasn't changed, handle as an avatar change.
                                        notificationBody = NotificationService.localizedString(forKey: "USER_UPDATED_AVATAR", eventSenderName)
                                    }
                                } else {
                                    // No known reports of having reached this situation for a membership notification
                                    // So use a generic membership updated fallback.
                                    notificationBody = NotificationService.localizedString(forKey: "USER_MEMBERSHIP_UPDATED", eventSenderName)
                                }
                            // Otherwise treat the notification as an invite.
                            // This is the expected notification content for a membership event.
                            } else {
                                if let roomDisplayName = roomDisplayName, roomDisplayName != eventSenderName {
                                    notificationBody = NotificationService.localizedString(forKey: "USER_INVITE_TO_NAMED_ROOM", eventSenderName, roomDisplayName)
                                } else {
                                    notificationBody = NotificationService.localizedString(forKey: "USER_INVITE_TO_CHAT", eventSenderName)
                                }
                            }
                            
                        case .sticker:
                            notificationTitle = self.messageTitle(for: eventSenderName, in: roomDisplayName)
                            notificationBody = NotificationService.localizedString(forKey: "STICKER_FROM_USER", eventSenderName)
                        
                        // Reactions are unexpected notification types, but have been seen in some circumstances.
                        case .reaction:
                            notificationTitle = self.messageTitle(for: eventSenderName, in: roomDisplayName)
                            if let reactionKey = event.relatesTo?.key {
                                // Try to show the reaction key in the notification.
                                notificationBody = NotificationService.localizedString(forKey: "REACTION_FROM_USER", eventSenderName, reactionKey)
                            } else {
                                // Otherwise show a generic reaction.
                                notificationBody = NotificationService.localizedString(forKey: "GENERIC_REACTION_FROM_USER", eventSenderName)
                            }

                        case .custom:
                            if (event.type == kWidgetMatrixEventTypeString || event.type == kWidgetModularEventTypeString),
                               let type = event.content?["type"] as? String,
                               (type == kWidgetTypeJitsiV1 || type == kWidgetTypeJitsiV2) {
                                notificationBody = NotificationService.localizedString(forKey: "GROUP_CALL_STARTED")
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
                        
                        case .pollEnd:
                            notificationTitle = self.messageTitle(for: eventSenderName, in: roomDisplayName)
                            notificationBody = VectorL10n.pollTimelineEndedText
                        
                        case .callNotify:
                            if let callNotify = MXCallNotify(fromJSON: event.content) {
                                let userIDs = callNotify.mentions.userIDs as? [String]
                                if currentUserId.flatMap({ userIDs?.contains($0) }) ?? callNotify.mentions.room {
                                    notificationTitle = self.messageTitle(for: eventSenderName, in: roomDisplayName)
                                    notificationBody = NotificationService.localizedString(forKey: "UNSUPPORTED_CALL")
                                }
                            }
                        
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
            validatedNotificationBody = NotificationService.localizedString(forKey: "MESSAGE_PROTECTED")
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
            return NotificationService.localizedString(forKey: "MSG_FROM_USER_IN_ROOM_TITLE", eventSenderName, roomDisplayName)
        } else {
            return eventSenderName
        }
    }
    
    private func replyTitle(for eventSenderName: String, in roomDisplayName: String?) -> String {
        // Display the room name only if it is different than the sender name
        if let roomDisplayName = roomDisplayName, roomDisplayName != eventSenderName {
            return NotificationService.localizedString(forKey: "REPLY_FROM_USER_IN_ROOM_TITLE", eventSenderName, roomDisplayName)
        } else {
            return NotificationService.localizedString(forKey: "REPLY_FROM_USER_TITLE", eventSenderName)
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
        if let threadId = event.threadId {
            notificationUserInfo["thread_id"] = threadId
        }
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
        
        guard event.eventType == .roomMessage || event.eventType == .roomEncrypted || event.eventType == .callNotify else {
            return Constants.toBeRemovedNotificationCategoryIdentifier
        }
        
        // Don't return QUICK_REPLY here as there is an issue
        // with crypto corruption when sending from extensions.
        return nil
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
        
        mxRestClient.sendReadReceipt(toRoom: roomId, forEvent: eventId, threadId: event.threadId) { response in
            if response.isSuccess {
                MXLog.debug("[NotificationService] sendReadReceipt: Read receipt send successfully.")
            } else if let error = response.error {
                MXLog.error("[NotificationService] sendReadReceipt: Read receipt send failed", context: error)
            }
        }
    }
    
    private static func localizedString(forKey key: String, _ args: CVarArg...) -> String {
        // The bundle needs to be an MXKLanguageBundle and contain the lproj files.
        // MatrixKit now sets the app bundle as the MXKLanguageBundle
        let format = NSLocalizedString(key, bundle: Bundle.app, comment: "")
        let locale = LocaleProvider.locale ?? Locale.current
        
        return String(format: format, locale: locale, arguments: args)
    }
}

private extension MXPushRule {
    var dontNotify: Bool {
        let actions = (actions as? [MXPushRuleAction]) ?? []
        // Support for MSC3987: The dont_notify push rule action is deprecated and replaced by an empty actions list.
        return actions.isEmpty || actions.contains { $0.actionType == MXPushRuleActionTypeDontNotify }
    }
}
