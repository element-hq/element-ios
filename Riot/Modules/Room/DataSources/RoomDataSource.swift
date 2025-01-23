// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension RoomDataSource {
    // MARK: - Private Constants
    private enum Constants {
        static let emoteMessageSlashCommandPrefix = String(format: "%@ ", MXKSlashCommand.emote.cmd)
    }
    
    // MARK: - NSAttributedString Sending
    /// Send a text message to the room.
    /// While sending, a fake event will be echoed in the messages list.
    /// Once complete, this local echo will be replaced by the event saved by the homeserver.
    ///
    /// - Parameters:
    ///   - attributedText: the attributed text to send
    ///   - completion: http operation completion block
    func sendAttributedTextMessage(_ attributedText: NSAttributedString,
                                   completion: @escaping (MXResponse<String?>) -> Void) {
        var localEcho: MXEvent?
        
        let isEmote = isAttributedTextMessageAnEmote(attributedText)
        let sanitized = sanitizedAttributedMessageText(attributedText)
        let rawText: String
        let html: String? = htmlMessageFromSanitizedAttributedText(sanitized)
        if #available(iOS 15.0, *) {
            rawText = PillsFormatter.stringByReplacingPills(in: sanitized)
        } else {
            rawText = sanitized.string
        }
        
        if isEmote {
            room.sendEmote(rawText,
                           formattedText: html,
                           threadId: self.threadId,
                           localEcho: &localEcho,
                           completion: completion)
        } else {
            room.sendTextMessage(rawText,
                                 formattedText: html,
                                 threadId: self.threadId,
                                 localEcho: &localEcho,
                                 completion: completion)
        }
        
        if localEcho != nil {
            self.queueEvent(forProcessing: localEcho, with: self.roomState, direction: .forwards)
            self.processQueuedEvents(nil)
        }
    }
    
    // MARK: - NSAttributedString Sending
    /// Send a text message to the room.
    /// While sending, a fake event will be echoed in the messages list.
    /// Once complete, this local echo will be replaced by the event saved by the homeserver.
    ///
    /// - Parameters:
    ///   - rawText: the raw text to send
    ///   - html: the formatted html to send
    ///   - completion: http operation completion block
    func sendFormattedTextMessage(_ rawText: String,
                                  html: String,
                                  completion: @escaping (MXResponse<String?>) -> Void) {
        var localEcho: MXEvent?
        room.sendTextMessage(rawText,
                             formattedText: html,
                             threadId: self.threadId,
                             localEcho: &localEcho,
                             completion: completion)
        
        if localEcho != nil {
            self.queueEvent(forProcessing: localEcho, with: self.roomState, direction: .forwards)
            self.processQueuedEvents(nil)
        }
    }
    
    /// Send a reply to an event with text message to the room.
    ///
    /// While sending, a fake event will be echoed in the messages list.
    /// Once complete, this local echo will be replaced by the event saved by the homeserver.
    ///
    /// - Parameters:
    ///   - eventToReply: the event to reply
    ///   - attributedText: the attributed text to send
    ///   - completion: http operation completion block
    func sendReply(to eventToReply: MXEvent,
                   withAttributedTextMessage attributedText: NSAttributedString,
                   completion: @escaping (MXResponse<String?>) -> Void) {
        let sanitized = sanitizedAttributedMessageText(attributedText)
        let rawText: String
        let html: String? = htmlMessageFromSanitizedAttributedText(sanitized)
        if #available(iOS 15.0, *) {
            rawText = PillsFormatter.stringByReplacingPills(in: sanitized)
        } else {
            rawText = sanitized.string
        }
        
        handleFormattedSendReply(to: eventToReply, rawText: rawText, html: html, completion: completion)
    }
    
    /// Send a reply to an event with a html formatted  text message to the room.
    ///
    /// While sending, a fake event will be echoed in the messages list.
    /// Once complete, this local echo will be replaced by the event saved by the homeserver.
    ///
    /// - Parameters:
    ///   - eventToReply: the event to reply
    ///   - rawText: the raw text to send
    ///   - htmlText: the html text to send
    ///   - completion: http operation completion block
    func sendReply(to eventToReply: MXEvent,
                   rawText: String,
                   htmlText: String,
                   completion: @escaping (MXResponse<String?>) -> Void) {
        
       handleFormattedSendReply(to: eventToReply, rawText: rawText, html: htmlText, completion: completion)
    }
    
    
    /// Replace a text in an event.
    ///
    /// - Parameters:
    ///   - event: The event to replace
    ///   - attributedText: The new attributed message text
    ///   - success: A block object called when the operation succeeds. It returns the event id of the event generated on the homeserver
    ///   - failure: A block object called when the operation fails
    func replaceAttributedTextMessage(for event: MXEvent,
                                      withAttributedTextMessage attributedText: NSAttributedString,
                                      success: @escaping ((String?) -> Void),
                                      failure: @escaping ((Error?) -> Void)) {
        let sanitized = sanitizedAttributedMessageText(attributedText)
        let rawText: String
        let html: String? = htmlMessageFromSanitizedAttributedText(sanitized)
        if #available(iOS 15.0, *) {
            rawText = PillsFormatter.stringByReplacingPills(in: sanitized)
        } else {
            rawText = sanitized.string
        }
        
        handleReplaceFormattedMessage(for: event, rawText: rawText, html: html, success: success, failure: failure)
    }
    
    /// Replace a formatted html text in an event
    ///
    /// - Parameters:
    ///   - event: The event to replace
    ///   - rawText: The new rawText
    ///   - html: The new html text
    ///   - success: A block object called when the operation succeeds. It returns the event id of the event generated on the homeserver
    ///   - failure: A block object called when the operation fails
    func replaceFormattedTextMessage( for event: MXEvent,
                                      rawText: String,
                                      html: String,
                                      success: @escaping ((String?) -> Void),
                                      failure: @escaping ((Error?) -> Void)) {
        handleReplaceFormattedMessage(for: event, rawText: rawText, html: html, success: success, failure: failure)
    }

    /// Retrieve editable attributed text message from an event.
    /// 
    /// - Parameter event: the event
    /// - Returns: event attributed text editable by user
    @objc func editableAttributedTextMessage(for event: MXEvent) -> NSAttributedString? {
        let editableTextMessage: NSAttributedString?

        if event.isReply() {
            let body: String
            if let newContent = event.content[kMXMessageContentKeyNewContent] as? [String: Any] {
                // Use new content if available.
                body = newContent["formatted_body"] as? String ?? newContent[kMXMessageBodyKey] as? String ?? ""
            } else {
                // Otherwise parse MXReply.
                let parser = MXReplyEventParser()
                let replyEventParts = parser.parse(event)

                body = replyEventParts?.formattedBodyParts?.replyText ?? replyEventParts?.bodyParts.replyText ?? ""
            }

            let attributed = eventFormatter.renderHTMLString(body, for: event, with: nil, andLatestRoomState: nil)
            if let attributed = attributed, #available(iOS 15.0, *) {
                editableTextMessage = PillsFormatter.insertPills(in: attributed,
                                                                 withSession: self.mxSession,
                                                                 eventFormatter: self.eventFormatter,
                                                                 event: event,
                                                                 roomState: self.roomState,
                                                                 andLatestRoomState: nil,
                                                                 isEditMode: true)
            } else {
                editableTextMessage = attributed
            }
        } else {
            let body: String = event.content["formatted_body"] as? String ?? event.content["body"] as? String ?? ""
            let attributed = eventFormatter.renderHTMLString(body, for: event, with: nil, andLatestRoomState: nil)
            if let attributed = attributed, #available(iOS 15.0, *) {
                editableTextMessage = PillsFormatter.insertPills(in: attributed,
                                                                 withSession: self.mxSession,
                                                                 eventFormatter: self.eventFormatter,
                                                                 event: event,
                                                                 roomState: self.roomState,
                                                                 andLatestRoomState: nil,
                                                                 isEditMode: true)
            } else {
                editableTextMessage = attributed
            }
        }

        return editableTextMessage
    }
    
    @objc func editableHtmlTextMessage(for event: MXEvent) -> String {
        event.content["formatted_body"] as? String ?? event.content["body"] as? String ?? ""
    }
}

// MARK: - Private Helpers
private extension RoomDataSource {
    func sanitizedAttributedMessageText(_ attributedString: NSAttributedString) -> NSAttributedString {
        let newAttr = NSMutableAttributedString(attributedString: attributedString)
        newAttr.mutableString.replaceOccurrences(of: String(format: "%C", 0x00000000), with: "", range: .init(location: 0, length: newAttr.length))

        if isAttributedTextMessageAnEmote(attributedString) {
            // Remove "/me " string
            newAttr.mutableString.replaceCharacters(in: .init(location: 0, length: Constants.emoteMessageSlashCommandPrefix.count),
                                                    with: "")
        }

        return newAttr
    }

    func htmlMessageFromSanitizedAttributedText(_ sanitizedText: NSAttributedString) -> String? {
        let rawText: String
        if #available(iOS 15.0, *) {
            rawText = PillsFormatter.stringByReplacingPills(in: sanitizedText, mode: .markdown)
        } else {
            rawText = sanitizedText.string
        }

        let html = eventFormatter.htmlString(fromMarkdownString: rawText)

        return html == sanitizedText.string ? nil : html
    }

    func isAttributedTextMessageAnEmote(_ attributedText: NSAttributedString) -> Bool {
        return attributedText.string.starts(with: Constants.emoteMessageSlashCommandPrefix)
    }
    
    func handleReplaceFormattedMessage(for event: MXEvent,
                                                rawText: String,
                                                html: String?,
                                                success: @escaping ((String?) -> Void),
                                                failure: @escaping ((Error?) -> Void)) {
        let eventBody = event.content[kMXMessageBodyKey] as? String
        let eventFormattedBody = event.content["formatted_body"] as? String
        if rawText != eventBody && (eventFormattedBody == nil || html != eventFormattedBody) {
            self.mxSession.aggregations.replaceTextMessageEvent(
                event,
                withTextMessage: rawText,
                formattedText: html,
                localEcho: { localEcho in
                    // Apply the local echo to the timeline
                    self.updateEvent(withReplace: localEcho)
                    
                    // Integrate the replace local event into the timeline like when sending a message
                    // This also allows to manage read receipt on this replace event
                    self.queueEvent(forProcessing: localEcho, with: self.roomState, direction: .forwards)
                    self.processQueuedEvents(nil)
                },
                success: success,
                failure: failure)
        } else {
            failure(nil)
        }
    }
    
    func handleFormattedSendReply(to eventToReply: MXEvent,
                                          rawText: String,
                                          html: String?,
                                          completion: @escaping (MXResponse<String?>) -> Void) {
        var localEcho: MXEvent?
        
        let stringLocalizer: MXSendReplyEventStringLocalizerProtocol = MXKSendReplyEventStringLocalizer()
        
        room.sendReply(to: eventToReply,
                       textMessage: rawText,
                       formattedTextMessage: html,
                       stringLocalizer: stringLocalizer,
                       threadId: self.threadId,
                       localEcho: &localEcho,
                       completion: completion)
        
        if localEcho != nil {
            self.queueEvent(forProcessing: localEcho, with: self.roomState, direction: .forwards)
            self.processQueuedEvents(nil)
        }
    }
}
