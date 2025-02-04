// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

/// Provides utilities funcs to handle Pills inside attributed strings.
@available(iOS 15.0, *)
@objcMembers
class PillsFormatter: NSObject {
    // MARK: - Internal Properties
    /// UTType identifier for pills. Should be declared as Document type & Exported type identifier inside Info.plist
    static let pillUTType: String = "im.vector.app.pills"

    // MARK: - Internal Enums
    /// Defines a replacement mode for converting Pills to plain text.
    @objc enum PillsReplacementTextMode: Int {
        case displayname
        case identifier
        case markdown
    }
    
    // MARK: - Internal Methods
    /// Insert text attachments for pills inside given message attributed string.
    ///
    /// - Parameters:
    ///   - attributedString: message string to update
    ///   - session: current session
    ///   - eventFormatter: the event formatter
    ///   - event: the event
    ///   - roomState: room state for message
    ///   - latestRoomState: latest room state of the room containing this message
    ///   - isEditMode: whether this string will be used in the composer
    /// - Returns: new attributed string with pills
    static func insertPills(in attributedString: NSAttributedString,
                            withSession session: MXSession,
                            eventFormatter: MXKEventFormatter,
                            event: MXEvent,
                            roomState: MXRoomState,
                            andLatestRoomState latestRoomState: MXRoomState?,
                            isEditMode: Bool = false) -> NSAttributedString {
                
        let newAttr = NSMutableAttributedString(attributedString: attributedString)
        newAttr.vc_enumerateAttribute(.link) { (url: URL, range: NSRange, _) in
            
            let provider = PillProvider(withSession: session,
                                        eventFormatter: eventFormatter,
                                        event: event,
                                        roomState: roomState,
                                        andLatestRoomState: latestRoomState,
                                        isEditMode: isEditMode)
                        
            // try to get a mention pill from the url
            let label = Range(range, in: newAttr.string).flatMap { String(newAttr.string[$0]) }
            if let attachmentString: NSAttributedString = provider.pillTextAttachmentString(forUrl: url, withLabel: label ?? "") {
                // replace the url with the pill
                newAttr.replaceCharacters(in: range, with: attachmentString)
            }
        }

        return newAttr
    }

    /// Insert text attachments for pills inside given attributed string containing markdown.
    ///
    /// - Parameters:
    ///   - markdownString: An attributed string with markdown formatting
    ///   - roomState: The current room state
    ///   - font: The font to use for the pill text
    /// - Returns: A new attributed string with pills.
    static func insertPills(in markdownString: NSAttributedString,
                            withSession session: MXSession,
                            eventFormatter: MXKEventFormatter,
                            roomState: MXRoomState,
                            font: UIFont) -> NSAttributedString {
        let matches = markdownLinks(in: markdownString)

        // If we have some matches, replace permalinks by a pill version.
        guard !matches.isEmpty else { return markdownString }

        let pillProvider = PillProvider(withSession: session,
                                        eventFormatter: eventFormatter,
                                        event: nil,
                                        roomState: roomState,
                                        andLatestRoomState: nil,
                                        isEditMode: true)

        let mutable = NSMutableAttributedString(attributedString: markdownString)

        matches.reversed().forEach {
            if let attachmentString = pillProvider.pillTextAttachmentString(forUrl: $0.url, withLabel: $0.label) {
                mutable.replaceCharacters(in: $0.range, with: attachmentString)
            }
        }

        return mutable
    }

    /// Creates a string with all pills of given attributed string replaced by display names.
    ///
    /// - Parameters:
    ///   - attributedString: attributed string with pills
    ///   - mode: replacement mode for pills (default: displayname)
    /// - Returns: string with display names
    static func stringByReplacingPills(in attributedString: NSAttributedString,
                                       mode: PillsReplacementTextMode = .displayname) -> String {
        let newAttr = NSMutableAttributedString(attributedString: attributedString)
        newAttr.vc_enumerateAttribute(.attachment) { (attachment: PillTextAttachment, range: NSRange, _) in
            guard let data = attachment.data else {
                return
            }

            let pillString: String
            switch mode {
            case .displayname:
                pillString = data.displayText
            case .identifier:
                pillString = data.pillIdentifier
            case .markdown:
                pillString = data.markdown
            }

            newAttr.replaceCharacters(in: range, with: pillString)
        }

        return newAttr.string
    }

    
    /// Creates an attributed string containing a pill for given room member.
    ///
    /// - Parameters:
    ///   - roomMember: the room member
    ///   - url: URL to room member profile. Should be provided to make pill act as a link.
    ///   - isHighlighted: true to indicate that the pill should be highlighted
    ///   - font: the text font
    /// - Returns: attributed string with a pill attachment and an optional link
    static func mentionPill(withRoomMember roomMember: MXRoomMember,
                            andUrl url: URL? = nil,
                            isHighlighted: Bool,
                            font: UIFont) -> NSAttributedString {

        guard let attachment = PillTextAttachment(withRoomMember: roomMember, isHighlighted: isHighlighted, font: font) else {
            return NSAttributedString(string: roomMember.displayname)
        }
        return attributedStringWithAttachment(attachment, link: url, font: font)
    }

    static func mentionPill(withUrl url: URL,
                            andLabel label: String,
                            session: MXSession,
                            eventFormatter: MXKEventFormatter,
                            roomState: MXRoomState) -> NSAttributedString? {
        let pillProvider = PillProvider(withSession: session,
                                        eventFormatter: eventFormatter,
                                        event: nil,
                                        roomState: roomState,
                                        andLatestRoomState: nil,
                                        isEditMode: true)
        return pillProvider.pillTextAttachmentString(forUrl: url, withLabel: label)
    }
        
    /// Update alpha of all `PillTextAttachment` contained in given attributed string.
    ///
    /// - Parameters:
    ///   - alpha: Alpha value to apply
    ///   - attributedString: Attributed string containing the pills
    static func setPillAlpha(_ alpha: CGFloat, inAttributedString attributedString: NSAttributedString) {
        attributedString.vc_enumerateAttribute(.attachment) { (pill: PillTextAttachment, range: NSRange, _) in
            pill.data?.alpha = alpha
        }
    }

    /// Refresh pills inside given attributed string.
    /// 
    /// - Parameters:
    ///   - attributedString: attributed string to update
    ///   - roomState: room state for refresh, should be the latest available
    static func refreshPills(in attributedString: NSAttributedString, with roomState: MXRoomState) {
        attributedString.vc_enumerateAttribute(.attachment) { (pill: PillTextAttachment, range: NSRange, _) in
            
            switch pill.data?.pillType {
            case .user(let userId):
                guard let roomMember = roomState.members.member(withUserId: userId) else {
                    return
                }
                
                let displayName = roomMember.displayname ?? userId

                pill.data?.items = [
                    .avatar(url: roomMember.avatarUrl,
                            string: displayName,
                            matrixId: userId),
                    .text(displayName)
                ]
            default:
                break
            }
        }
    }
}

// MARK: - Private Methods
@available(iOS 15.0, *)
extension PillsFormatter {
    struct MarkdownLinkResult: Equatable {
        let url: URL
        let label: String
        let range: NSRange
    }

    static func markdownLinks(in attributedString: NSAttributedString) -> [MarkdownLinkResult] {
        // Create a regexp that detects markdown links.
        // Pattern source: https://gist.github.com/hugocf/66d6cd241eff921e0e02
        let pattern = "\\[([^\\]]+)\\]\\(([^\\)\"\\s]+)(?:\\s+\"(.*)\")?\\)"
        guard let regExp = try? NSRegularExpression(pattern: pattern) else { return [] }

        let matches = regExp.matches(in: attributedString.string,
                                     range: .init(location: 0, length: attributedString.length))

        return matches.compactMap { match in
            let labelRange = match.range(at: 1)
            let urlRange = match.range(at: 2)
            let label = attributedString.attributedSubstring(from: labelRange).string
            var url = attributedString.attributedSubstring(from: urlRange).string

            // Note: a valid markdown link can be written with
            // enclosing <..>, remove them for userId detection.
            if url.first == "<" && url.last == ">" {
                url = String(url[url.index(after: url.startIndex)...url.index(url.endIndex, offsetBy: -2)])
            }

            if let url = URL(string: url) {
                return MarkdownLinkResult(url: url, label: label, range: match.range)
            } else {
                return nil
            }
        }
    }
    
    static func attributedStringWithAttachment(_ attachment: PillTextAttachment, link: URL?, font: UIFont) -> NSAttributedString {
        let string = NSMutableAttributedString(attachment: attachment)
        string.addAttribute(.font, value: font, range: .init(location: 0, length: string.length))
        if let url = link {
            string.addAttribute(.link, value: url, range: .init(location: 0, length: string.length))
        }
        return string
    }
}
