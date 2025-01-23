// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@available(iOS 15.0, *)
private enum PillAttachmentKind {
    case attachment(PillTextAttachment)
    case string(NSAttributedString)
}

@available(iOS 15.0, *)
struct PillProvider {
    private let session: MXSession
    private let eventFormatter: MXKEventFormatter
    private let event: MXEvent?
    private let roomState: MXRoomState
    private let latestRoomState: MXRoomState?
    private let isEditMode: Bool
    
    init(withSession session: MXSession,
         eventFormatter: MXKEventFormatter,
         event: MXEvent?,
         roomState: MXRoomState,
         andLatestRoomState latestRoomState: MXRoomState?,
         isEditMode: Bool) {
    
        self.session = session
        self.eventFormatter = eventFormatter
        self.event = event
        self.roomState = roomState
        self.latestRoomState = latestRoomState
        self.isEditMode = isEditMode
    }
    
    func pillTextAttachmentString(forUrl url: URL, withLabel label: String) -> NSAttributedString? {
        
        // Try to get a pill from this url
        guard let pillType = PillType.from(url: url) else {
            return nil
        }
                
        // Do not pillify an url if it is a markdown or an http link (except for user and room) with a custom text
        
        // First, we need to handle the case where the label can contains more than one # (room alias)
        var urlFromLabel = URL(string: label)?.absoluteURL
        if urlFromLabel == nil, label.filter({ $0 == "#" }).count > 1 {
            if let escapedLabel = label.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: escapedLabel) {
                urlFromLabel = Tools.fixURL(withSeveralHashKeys: url)
            }
        }
        
        let fixedUrl = Tools.fixURL(withSeveralHashKeys: url)
        let isUrlMarkDownLink = urlFromLabel != fixedUrl

        let result: PillAttachmentKind
        switch pillType {
        case .user(let userId):
            var userFound = false
            result = pillTextAttachment(forUserId: userId, userFound: &userFound)
            // if it is a markdown link and we didn't found the user, don't pillify it
            if isUrlMarkDownLink && !userFound {
                return nil
            }
        case .room(let roomId):
            var roomFound = false
            result = pillTextAttachment(forRoomId: roomId, roomFound: &roomFound)
            // if it is a markdown link and we didn't found the room, don't pillify it
            if isUrlMarkDownLink && !roomFound {
                return nil
            }
        case .message(let roomId, let messageId):
            // if it is a markdown link, don't pillify it
            if isUrlMarkDownLink {
                return nil
            }
            result = pillTextAttachment(forMessageId: messageId, inRoomId: roomId)
        }
        
        switch result {
        case .attachment(let pillTextAttachment):
            return PillsFormatter.attributedStringWithAttachment(pillTextAttachment, link: isEditMode ? nil : url, font: eventFormatter.defaultTextFont)
        case .string(let attributedString):
            // if we don't have an attachment, use the fallback attributed string
            let newAttrString = NSMutableAttributedString(attributedString: attributedString)
            if let font = eventFormatter.defaultTextFont {
                newAttrString.addAttribute(.font, value: font, range: .init(location: 0, length: newAttrString.length))
            }
            newAttrString.addAttribute(.foregroundColor, value: ThemeService.shared().theme.colors.links, range: .init(location: 0, length: newAttrString.length))
            newAttrString.addAttribute(.link, value: url, range: .init(location: 0, length: newAttrString.length))
            return newAttrString
        }
    }
    
    /// Retrieve the latest available `MXRoomMember` from given data.
    ///
    /// - Parameters:
    ///   - userId: the id of the user
    /// - Returns: the room member, if available
    private func roomMember(withUserId userId: String) -> MXRoomMember? {
        return latestRoomState?.members.member(withUserId: userId) ?? roomState.members.member(withUserId: userId)
    }
    
    /// Create a pill representation for a given user
    /// - Parameters:
    ///   - userId: the user MatrixID
    ///   - userFound: this flag will be set to true if a user is found locally with this userId
    /// - Returns: a pill attachment
    private func pillTextAttachment(forUserId userId: String, userFound: inout Bool) -> PillAttachmentKind {
        // Search for a room member matching this user id
        let roomMember = self.roomMember(withUserId: userId)
        var user: MXUser?
        
        if roomMember == nil {
            // fallback on getting the user from the session's store
            user = session.user(withUserId: userId)
        }

        
        let avatarUrl = roomMember?.avatarUrl ?? user?.avatarUrl
        let displayName = roomMember?.displayname ?? user?.displayName ?? userId
        let isHighlighted = userId == session.myUserId
            // No actual event means it is a composer Pill. No highlight
            && event != nil
            // No highlight on self-mentions
            && event?.sender != session.myUserId

        let avatar: PillTextAttachmentItem
        if roomMember == nil && user == nil {
            avatar = .asset(named: "pill_user",
                            parameters: .init(tintColor: PillAssetColor(uiColor: ThemeService.shared().theme.colors.secondaryContent),
                                              rawRenderingMode: UIImage.RenderingMode.alwaysOriginal.rawValue,
                                              padding: 0.0))
        } else {
            avatar = .avatar(url: avatarUrl,
                             string: displayName,
                             matrixId: userId)
        }

        let data = PillTextAttachmentData(pillType: .user(userId: userId),
                                          items: [
                                            avatar,
                                            .text(displayName)
                                          ],
                                          isHighlighted: isHighlighted,
                                          alpha: 1.0,
                                          font: eventFormatter.defaultTextFont)
        
        userFound = roomMember != nil || user != nil
        
        if let attachment = PillTextAttachment(attachmentData: data) {
            return .attachment(attachment)
        }
        
        return .string(NSMutableAttributedString(string: displayName))
    }
    
    /// Create a pill representation for a given room
    /// - Parameters:
    ///   - roomId: the room MXID or alias
    ///   - roomFound: this flag will be set to true if a room is found locally with this roomId
    /// - Returns: a pill attachment
    private func pillTextAttachment(forRoomId roomId: String, roomFound: inout Bool) -> PillAttachmentKind {
        // Get the room matching this roomId
        let room = roomId.starts(with: "#") ? session.room(withAlias: roomId) : session.room(withRoomId: roomId)
        let displayName = room?.displayName ?? VectorL10n.pillRoomFallbackDisplayName
        
        let avatar: PillTextAttachmentItem
        if let room {
            if session.spaceService.getSpace(withId: roomId) != nil {
                avatar = .spaceAvatar(url: room.avatarData.mxContentUri,
                                      string: displayName,
                                      matrixId: roomId)
            } else {
                avatar = .avatar(url: room.avatarData.mxContentUri,
                                 string: displayName,
                                 matrixId: roomId)
            }
        } else {
            avatar = .asset(named: "link_icon",
                            parameters: .init(backgroundColor: PillAssetColor(uiColor: ThemeService.shared().theme.colors.links),
                                              rawRenderingMode: UIImage.RenderingMode.alwaysTemplate.rawValue))
        }
        
        let data = PillTextAttachmentData(pillType: .room(roomId: roomId),
                                          items: [
                                            avatar,
                                            .text(displayName)
                                          ],
                                          isHighlighted: false,
                                          alpha: 1.0,
                                          font: eventFormatter.defaultTextFont)
        
        roomFound = room != nil
        
        if let attachment = PillTextAttachment(attachmentData: data) {
            return .attachment(attachment)
        }
        
        return .string(NSMutableAttributedString(string: displayName))
    }
        
    /// Create a pill representation for a message in a room
    /// - Parameters:
    ///   - messageId: message eventId
    ///   - roomId: roomId of the message
    /// - Returns: a pill attachment
    private func pillTextAttachment(forMessageId messageId: String, inRoomId roomId: String) -> PillAttachmentKind {
        
        // Check if this is the current room
        if roomId == roomState.roomId {
            return pillTextAttachment(inCurrentRoomForMessageId: messageId)
        }

        let room = session.room(withRoomId: roomId)

        let avatar: PillTextAttachmentItem
        if let room {
            avatar = .avatar(url: room.avatarData.mxContentUri,
                             string: room.displayName,
                             matrixId: roomId)
        } else {
            avatar = .asset(named: "link_icon",
                            parameters: .init(backgroundColor: PillAssetColor(uiColor: ThemeService.shared().theme.colors.links),
                                              rawRenderingMode: UIImage.RenderingMode.alwaysTemplate.rawValue))
                                              
        }
        
        let displayText = room?.displayName.flatMap { VectorL10n.pillMessageIn($0) } ?? VectorL10n.pillMessage

        let data = PillTextAttachmentData(pillType: .message(roomId: roomId, eventId: messageId),
                                          items: [
                                            avatar,
                                            .text(displayText)
                                          ],
                                          isHighlighted: false,
                                          alpha: 1.0,
                                          font: eventFormatter.defaultTextFont)
        
        if let attachment = PillTextAttachment(attachmentData: data) {
            return .attachment(attachment)
        }
        
        return .string(NSMutableAttributedString(string: displayText))
    }
    
    /// Create a pill representation for a message in the current room
    /// - Parameters:
    ///   - messageId: message eventId
    /// - Returns: a pill attachment
    private func pillTextAttachment(inCurrentRoomForMessageId messageId: String) -> PillAttachmentKind {
        var roomMember: MXRoomMember?
        // If we have the event locally, try to get the room member
        if let event = session.store.event(withEventId: messageId, inRoom: roomState.roomId) {
            roomMember = self.roomMember(withUserId: event.sender)
        }

        let displayText: String
        let avatar: PillTextAttachmentItem
        if let roomMember {
            displayText = VectorL10n.pillMessageFrom(roomMember.displayname ?? roomMember.userId)
            avatar = .avatar(url: roomMember.avatarUrl,
                             string: roomMember.displayname,
                             matrixId: roomMember.userId)
        } else {
            displayText = VectorL10n.pillMessage
            avatar = .asset(named: "link_icon",
                            parameters: .init(backgroundColor: PillAssetColor(uiColor: ThemeService.shared().theme.colors.links),
                                              rawRenderingMode: UIImage.RenderingMode.alwaysTemplate.rawValue))
        }

        let data = PillTextAttachmentData(pillType: .message(roomId: roomState.roomId, eventId: messageId),
                                          items: [
                                            avatar,
                                            .text(displayText)
                                          ].compactMap { $0 },
                                          isHighlighted: false,
                                          alpha: 1.0,
                                          font: eventFormatter.defaultTextFont)

        if let attachment = PillTextAttachment(attachmentData: data) {
            return .attachment(attachment)
        }

        return .string(NSMutableAttributedString(string: displayText))
    }
}
