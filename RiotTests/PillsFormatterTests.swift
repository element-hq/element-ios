// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest
@testable import Element

// MARK: - Inputs
private enum Inputs {
    static let messageStart = "Hello "
    static let aliceDisplayname = "Alice"
    static let aliceUserId = "@alice:matrix.org"
    static let aliceAvatarUrl = "mxc://matrix.org/VyNYAgahaiAzUoOeZETtQ"
    static let aliceAwayDisplayname = "Alice_away"
    static let aliceNewAvatarUrl = "mxc://matrix.org/VyNYAgaFdlLojoOeZETtQ"
    static let aliceMember = FakeMXRoomMember(displayname: aliceDisplayname, avatarUrl: aliceAvatarUrl, userId: aliceUserId)
    static let aliceMemberAway = FakeMXRoomMember(displayname: aliceAwayDisplayname, avatarUrl: aliceNewAvatarUrl, userId: "@alice:matrix.org")
    static let alicePermalink = "https://matrix.to/#/@alice:matrix.org"
    static let mentionToAlice = NSAttributedString(string: aliceDisplayname, attributes: [.link: URL(string: alicePermalink)!])
    static let markdownLinkToAlice = "[\(aliceDisplayname)](\(alicePermalink))"

    static let bobUserId = "@bob:matrix.org"
    static let bobDisplayname = "Bob"
    static let bobAvatarUrl = "mxc://matrix.org/VyNYBgahazAzUuOeZETtQ"
    static let bobMember = FakeMXRoomMember(displayname: bobDisplayname, avatarUrl: bobAvatarUrl, userId: bobUserId)
    static let bobPermalink = "https://matrix.to/#/@bob:matrix.org"
    static let markdownLinkToBob = "[\(bobDisplayname)](\(bobPermalink))"
    
    static let anotherUserId = "@another.user:matrix.org"
    static let anotherUserPermalink = "https://matrix.to/#/@another.user:matrix.org"
    static let markdownLinkToAnotherUser = "[Another user](\(alicePermalink))"
    static let mentionToAnotherUser = NSAttributedString(string: anotherUserPermalink, attributes: [.link: URL(string: anotherUserPermalink)!])
    static let mentionToAnotherUserWithLabel = NSAttributedString(string: "Link text", attributes: [.link: URL(string: anotherUserPermalink)!])
    
    static let roomId = "!vWieJcXcUdMwavNSvy:matrix.org"
    static let roomAlias = "#fake_room_alias:matrix.org"
    static let roomDisplayName = "Sample Room"
    static let roomPermalink = "https://matrix.to/#/\(roomId)"
    static let roomAliasPermalink = "https://matrix.to/%23/\(roomAlias)"
    static let roomAvatarUrl = "mxc://matrix.org/VzNZAgahaiAzUoOeZETtQ"
    static let mentionToRoom = NSAttributedString(string: roomPermalink, attributes: [.link: URL(string: roomPermalink)!])
    static let mentionToRoomWithLabel = NSAttributedString(string: roomDisplayName, attributes: [.link: URL(string: roomPermalink)!])
    static let mentionToRoomAlias = NSAttributedString(string: roomDisplayName, attributes: [.link: URL(string: roomAliasPermalink)!])
    
    static let anotherRoomId = "!zWieBcUcUdMwavNSvy:matrix.org"
    static let anotherRoomDisplayName = "Room/Space"
    static let anotherRoomAvatarUrl = "mxc://matrix.org/VzNZBgajauAzUoOeZETtQ"
    
    static let messageEventId = "$JrEsoQO77MCdAubG6z-5oXlOBy1I5QL9FTut_Giztoc"
    static let messagePermalink = "https://matrix.to/#/\(roomId)/\(messageEventId)?via=matrix.org"
    static let messageAnotherRoomPermalink = "https://matrix.to/#/\(anotherRoomId)/\(messageEventId)?via=matrix.org"
    
    static let pillAnotherUserWithLinkText = "Link text"
    static let pillMessageAnotherRoomText = "Message in Sample Room"
    static let pillMessageFromBobText = "Message from Bob"
}

// MARK: - Tests
@available(iOS 15.0, *)
class PillsFormatterTests: XCTestCase {
    func testPillsInsertionAndRefresh() {
        let messageWithPills = createMessageWithMentionFromBobToAlice()
        XCTAssertEqual(messageWithPills.length, Inputs.messageStart.count + 1) // +1 non-unicode character for the pill/textAttachment
        XCTAssert(messageWithPills.attribute(.attachment, at: messageWithPills.length - 1, effectiveRange: nil) is PillTextAttachment)

        let pillTextAttachment = messageWithPills.attribute(.attachment, at: messageWithPills.length - 1, effectiveRange: nil) as? PillTextAttachment
        // Alice's pill is highlighted.
        XCTAssert(pillTextAttachment?.data?.isHighlighted == true)
        // Attachment has correct type.
        XCTAssert(pillTextAttachment?.fileType == PillsFormatter.pillUTType)
        // Pill data contains Alice's displayname and avatar url.
        XCTAssertNotNil(pillTextAttachment?.data)
        let pillTextAttachmentData: PillTextAttachmentData! = pillTextAttachment?.data
        XCTAssertEqual(pillTextAttachmentData.displayText, Inputs.aliceDisplayname)
        switch pillTextAttachmentData.pillType {
        case .user(let userId):
            XCTAssertEqual(userId, Inputs.aliceUserId)
            switch pillTextAttachmentData.items.first {
            case .avatar(let url, _, _):
                XCTAssertEqual(url, Inputs.aliceAvatarUrl)
            default:
                XCTFail("First pill item should be the avatar")
            }
        default:
            XCTFail("Pill should be of type .user")
        }
        
        // Pill has expected size.
        let expectedSize = pillTextAttachment?.size(forFont: pillTextAttachment!.data!.font)
        XCTAssertEqual(pillTextAttachment?.bounds.size, expectedSize)

        PillsFormatter.refreshPills(in: messageWithPills,
                                    with: FakeMXRoomState(roomMembers: FakeMXUpdatedRoomMembers()))
        let refreshedPillTextAttachment = messageWithPills.attribute(.attachment, at: messageWithPills.length - 1, effectiveRange: nil) as? PillTextAttachment
        // Alice's pill is still highlighted.
        XCTAssert(pillTextAttachment?.data?.isHighlighted == true)
        // Pill data is refreshed with correct data.
        let updatedPillTextAttachmentData: PillTextAttachmentData! = pillTextAttachment?.data
        XCTAssertEqual(updatedPillTextAttachmentData.displayText, Inputs.aliceAwayDisplayname)
        switch updatedPillTextAttachmentData.pillType {
        case .user(let userId):
            XCTAssertEqual(userId, Inputs.aliceUserId)
            switch updatedPillTextAttachmentData.items.first  {
            case .avatar(let url, _, _):
                XCTAssertEqual(url, Inputs.aliceNewAvatarUrl)
            default:
                XCTFail("First pill item should be the avatar")
            }
        default:
            XCTFail("Pill should be of type .user")
        }
        
        // Pill size is updated
        let newExpectedSize = pillTextAttachment?.size(forFont: refreshedPillTextAttachment!.data!.font)
        XCTAssertEqual(refreshedPillTextAttachment?.bounds.size, newExpectedSize)
    }

    func testPillsUsingLatestRoomState() {
        let messageWithPills = createMessageWithMentionFromBobToAliceWithLatestRoomState()
        let pillTextAttachment = messageWithPills.attribute(.attachment, at: messageWithPills.length - 1, effectiveRange: nil) as? PillTextAttachment
        // Pill uses the latest room state data.
        XCTAssertNotNil(pillTextAttachment?.data)
        let pillTextAttachmentData: PillTextAttachmentData! = pillTextAttachment?.data
        XCTAssertEqual(pillTextAttachmentData.displayText, Inputs.aliceAwayDisplayname)
        switch pillTextAttachmentData.pillType {
        case .user(let userId):
            XCTAssertEqual(userId, Inputs.aliceUserId)
            switch pillTextAttachmentData.items.first  {
            case .avatar(let url, _, _):
                XCTAssertEqual(url, Inputs.aliceNewAvatarUrl)
            default:
                XCTFail("First pill item should be the avatar")
            }
        default:
            XCTFail("Pill should be of type .message")
        }
    }

    func testPillsToMarkdown() {
        let messageWithPills = createMessageWithMentionFromBobToAlice()
        let markdownMessage = PillsFormatter.stringByReplacingPills(in: messageWithPills, mode: .markdown)
        XCTAssertEqual(markdownMessage, Inputs.messageStart + Inputs.markdownLinkToAlice)
    }

    func testPillsToRawBody() {
        let messageWithPills = createMessageWithMentionFromBobToAlice()
        let messageWithDisplayname = PillsFormatter.stringByReplacingPills(in: messageWithPills, mode: .displayname)
        let messageWithUserId = PillsFormatter.stringByReplacingPills(in: messageWithPills, mode: .identifier)
        XCTAssertEqual(messageWithDisplayname, Inputs.messageStart + Inputs.aliceDisplayname)
        XCTAssertEqual(messageWithUserId, Inputs.messageStart + Inputs.aliceUserId)
    }
    
    // Test case: a mention to an unknown user (not a room member)
    func testPillMentionningRoomMember() {
        let messageWithPills = createMessageWithMentionFromBobToAlice()
        let pillTextAttachment = messageWithPills.attribute(.attachment, at: messageWithPills.length - 1, effectiveRange: nil) as? PillTextAttachment
        // Pill uses the latest room state data.
        XCTAssertNotNil(pillTextAttachment?.data)
        let pillTextAttachmentData: PillTextAttachmentData! = pillTextAttachment?.data
        XCTAssertEqual(pillTextAttachmentData.displayText, Inputs.aliceDisplayname)
        switch pillTextAttachmentData.pillType {
        case .user(let userId):
            XCTAssertEqual(userId, Inputs.aliceUserId)
            switch pillTextAttachmentData.items.first  {
            case .avatar(let url, _, _):
                XCTAssertEqual(url, Inputs.aliceAvatarUrl)
            default:
                XCTFail("First pill item should be the avatar")
            }
        default:
            XCTFail("Pill should be of type .user")
        }
    }
    
    // Test case: a mention to an unknown user (not a room member)
    func testPillMentionningUnknownUser() {
        let messageWithPills = createMessageWithMentionFromBobToAnotherUser()
        let pillTextAttachment = messageWithPills.attribute(.attachment, at: messageWithPills.length - 1, effectiveRange: nil) as? PillTextAttachment
        // Pill uses the latest room state data.
        XCTAssertNotNil(pillTextAttachment?.data)
        let pillTextAttachmentData: PillTextAttachmentData! = pillTextAttachment?.data
        XCTAssertEqual(pillTextAttachmentData.displayText, Inputs.anotherUserId)
        switch pillTextAttachmentData.pillType {
        case .user(let userId):
            XCTAssertEqual(userId, Inputs.anotherUserId)
            switch pillTextAttachmentData.items.first  {
            case .asset(let name, _):
                XCTAssertEqual(name, "pill_user")
            default:
                XCTFail("First pill item should be the asset")
            }
        default:
            XCTFail("Pill should be of type .user")
        }
    }
    
    // Test case: a mention to an unknown user (not a room member) with a formatted text (HTML or MARKDOWN)
    // In this case, we don't want to pillify the link
    func testPillMentionningUnknownUserWithFormattedText() {
        let messageWithPills = createMessageWithMentionFromBobToAnotherUser(withLinkText: true)
        let pillTextAttachment = messageWithPills.attribute(.attachment, at: messageWithPills.length - 1, effectiveRange: nil) as? PillTextAttachment
        XCTAssertNil(pillTextAttachment)
    }
    
    // Test case: a mention to a room
    func testPillMentionningRoom() {
        let messageWithPills = createMessageWithMentionToRoom()
        XCTAssertEqual(messageWithPills.length, Inputs.messageStart.count + 1) // +1 non-unicode character for the pill/textAttachment
        XCTAssert(messageWithPills.attribute(.attachment, at: messageWithPills.length - 1, effectiveRange: nil) is PillTextAttachment)

        let pillTextAttachment = messageWithPills.attribute(.attachment, at: messageWithPills.length - 1, effectiveRange: nil) as? PillTextAttachment
        // Pill is not highlighted.
        XCTAssert(pillTextAttachment?.data?.isHighlighted == false)
        // Attachment has correct type.
        XCTAssert(pillTextAttachment?.fileType == PillsFormatter.pillUTType)
        // Pill data contains the correct displayname and avatar url.
        XCTAssertNotNil(pillTextAttachment?.data)
        let pillTextAttachmentData: PillTextAttachmentData! = pillTextAttachment?.data
        XCTAssertEqual(pillTextAttachmentData.displayText, Inputs.roomDisplayName)
        switch pillTextAttachmentData.pillType {
        case .room(let userId):
            XCTAssertEqual(userId, Inputs.roomId)
            switch pillTextAttachmentData.items.first  {
            case .avatar(let url, _, _):
                XCTAssertEqual(url, Inputs.roomAvatarUrl)
            default:
                XCTFail("First pill item should be the avatar")
            }
        default:
            XCTFail("Pill should be of type .room")
        }
    }
    
    // Test case: a mention to a space
    func testPillMentionningSpace() {
        let messageWithPills = createMessageWithMentionToRoom(isSpace: true)

        let pillTextAttachment = messageWithPills.attribute(.attachment, at: messageWithPills.length - 1, effectiveRange: nil) as? PillTextAttachment
        // Pill is not highlighted.
        XCTAssert(pillTextAttachment?.data?.isHighlighted == false)
        // Attachment has correct type.
        XCTAssert(pillTextAttachment?.fileType == PillsFormatter.pillUTType)
        // Pill data contains the correct displayname and avatar url.
        XCTAssertNotNil(pillTextAttachment?.data)
        let pillTextAttachmentData: PillTextAttachmentData! = pillTextAttachment?.data
        XCTAssertEqual(pillTextAttachmentData.displayText, Inputs.roomDisplayName)
        switch pillTextAttachmentData.pillType {
        case .room(let userId):
            XCTAssertEqual(userId, Inputs.roomId)
            switch pillTextAttachmentData.items.first  {
            case .spaceAvatar(let url, _, _):
                XCTAssertEqual(url, Inputs.roomAvatarUrl)
            default:
                XCTFail("First pill item should be the spaceAvatar")
            }
        default:
            XCTFail("Pill should be of type .room")
        }
    }
    
    // Test case: a mention to a room alias
    func testPillMentionningRoomByAlias() {
        let messageWithPills = createMessageWithMentionToRoom(usingAlias: true)
        let pillTextAttachment = messageWithPills.attribute(.attachment, at: messageWithPills.length - 1, effectiveRange: nil) as? PillTextAttachment
        // Pill is not highlighted.
        XCTAssert(pillTextAttachment?.data?.isHighlighted == false)
        // Attachment has correct type.
        XCTAssert(pillTextAttachment?.fileType == PillsFormatter.pillUTType)
        // Pill data contains the correct displayname and avatar url.
        XCTAssertNotNil(pillTextAttachment?.data)
        let pillTextAttachmentData: PillTextAttachmentData! = pillTextAttachment?.data
        XCTAssertEqual(pillTextAttachmentData.displayText, Inputs.roomDisplayName)
        switch pillTextAttachmentData.pillType {
        case .room(let userId):
            XCTAssertEqual(userId, Inputs.roomAlias)
            switch pillTextAttachmentData.items.first  {
            case .avatar(let url, _, _):
                XCTAssertEqual(url, Inputs.roomAvatarUrl)
            default:
                XCTFail("First pill item should be the avatar")
            }
        default:
            XCTFail("Pill should be of type .room")
        }
    }
    
    // Test case: a mention to an unknown room
    func testPillMentionningUnknownRoom() {
        let messageWithPills = createMessageWithMentionToRoom(knownRoom: false)
        let pillTextAttachment = messageWithPills.attribute(.attachment, at: messageWithPills.length - 1, effectiveRange: nil) as? PillTextAttachment
        // Pill is not highlighted.
        XCTAssert(pillTextAttachment?.data?.isHighlighted == false)
        // Attachment has correct type.
        XCTAssert(pillTextAttachment?.fileType == PillsFormatter.pillUTType)
        // Pill data contains the correct displayname and avatar url.
        XCTAssertNotNil(pillTextAttachment?.data)
        let pillTextAttachmentData: PillTextAttachmentData! = pillTextAttachment?.data
        XCTAssertEqual(pillTextAttachmentData.displayText, VectorL10n.pillRoomFallbackDisplayName)
        switch pillTextAttachmentData.pillType {
        case .room(let userId):
            XCTAssertEqual(userId, Inputs.roomId)
            switch pillTextAttachmentData.items.first {
            case .asset(let assetName, _):
                XCTAssertEqual(assetName, "link_icon")
            default:
                XCTFail("First pill item should be the asset")
            }
        default:
            XCTFail("Pill should be of type .room")
        }
    }
    
    // Test case: a mention to an unknown room using a formatted text (HTML or MARKDOWN)
    func testPillMentionningUnknownRoomWithFormattedText() {
        let messageWithPills = createMessageWithMentionToRoom(knownRoom: false, withLinkText: "Link label")
        let pillTextAttachment = messageWithPills.attribute(.attachment, at: messageWithPills.length - 1, effectiveRange: nil) as? PillTextAttachment
        XCTAssertNil(pillTextAttachment)
    }
    
    // Test case: a mention to a message using a formatted text (HTML or MARKDOWN)
    func testPillMentionningMessageWithLabel() {
        let messageWithPills = createMessageWithMentionToMessage(from: Inputs.bobMember, withLabel: "Link label")
        let pillTextAttachment = messageWithPills.attribute(.attachment, at: messageWithPills.length - 1, effectiveRange: nil) as? PillTextAttachment
        XCTAssertNil(pillTextAttachment)
    }
    
    // Test case: a mention to a message sent by a room member in the current room
    func testPillMentionningMessageInCurrentRoomFromRoomMember() {
        // Test: a mention to current room message, sent by a room member (Bob)
        let messageWithPills = createMessageWithMentionToMessage(from: Inputs.bobMember, withLabel: Inputs.messagePermalink)
        let pillTextAttachment = messageWithPills.attribute(.attachment, at: messageWithPills.length - 1, effectiveRange: nil) as? PillTextAttachment
        // Pill is not highlighted.
        XCTAssert(pillTextAttachment?.data?.isHighlighted == false)
        // Attachment has correct type.
        XCTAssert(pillTextAttachment?.fileType == PillsFormatter.pillUTType)
        // Pill data contains the correct displayname and avatar url.
        XCTAssertNotNil(pillTextAttachment?.data)
        let pillTextAttachmentData: PillTextAttachmentData! = pillTextAttachment?.data
        XCTAssertEqual(pillTextAttachmentData.displayText, Inputs.pillMessageFromBobText)
        switch pillTextAttachmentData.pillType {
        case .message(let roomId, let messageId):
            XCTAssertEqual(roomId, Inputs.roomId)
            XCTAssertEqual(messageId, Inputs.messageEventId)
            let firstItem = pillTextAttachmentData.items[0]
            switch firstItem {
            case .avatar(let url, _, _):
                XCTAssertEqual(url, Inputs.bobAvatarUrl)
            default:
                XCTFail("First pill item should be the avatar")
            }
        default:
            XCTFail("Pill should be of type .message")
        }
    }
    
    // Test case: a mention to a message sent in the current room from an unknown user
    func testPillMentionningMessageInCurrentRoomFromUnknownUser() {
        let messageWithPills = createMessageWithMentionToMessage(sentBy: Inputs.anotherUserId, withLabel: Inputs.messagePermalink)
        let pillTextAttachment = messageWithPills.attribute(.attachment, at: messageWithPills.length - 1, effectiveRange: nil) as? PillTextAttachment
        // Pill is not highlighted.
        XCTAssert(pillTextAttachment?.data?.isHighlighted == false)
        // Attachment has correct type.
        XCTAssert(pillTextAttachment?.fileType == PillsFormatter.pillUTType)
        // Pill data contains the correct displayname and avatar url.
        XCTAssertNotNil(pillTextAttachment?.data)
        let pillTextAttachmentData: PillTextAttachmentData! = pillTextAttachment?.data
        XCTAssertEqual(pillTextAttachmentData.displayText, VectorL10n.pillMessage)
        
        switch pillTextAttachmentData.pillType {
        case .message(let roomId, let messageId):
            XCTAssertEqual(roomId, Inputs.roomId)
            XCTAssertEqual(messageId, Inputs.messageEventId)
            let firstItem = pillTextAttachmentData.items[0]
            switch firstItem {
            case .asset(let name, _):
                XCTAssertEqual(name, "link_icon")
            default:
                XCTFail("First pill item should be the asset")
            }
        default:
            XCTFail("Pill should be of type .message")
        }
    }
    
    // Test case: a mention to a message in another room
    func testPillMentionningMessageInAnotherRoom() {
        let messageWithPills = createMessageWithMentionToAnotherRoomMessage(knownRoom: true, withLabel: Inputs.messageAnotherRoomPermalink)
        let pillTextAttachment = messageWithPills.attribute(.attachment, at: messageWithPills.length - 1, effectiveRange: nil) as? PillTextAttachment
        // Pill is not highlighted.
        XCTAssert(pillTextAttachment?.data?.isHighlighted == false)
        // Attachment has correct type.
        XCTAssert(pillTextAttachment?.fileType == PillsFormatter.pillUTType)
        // Pill data contains the correct displayname and avatar url.
        XCTAssertNotNil(pillTextAttachment?.data)
        let pillTextAttachmentData: PillTextAttachmentData! = pillTextAttachment?.data
        XCTAssertEqual(pillTextAttachmentData.displayText, VectorL10n.pillMessageIn(Inputs.anotherRoomDisplayName))
        switch pillTextAttachmentData.pillType {
        case .message(let roomId, let messageId):
            XCTAssertEqual(roomId, Inputs.anotherRoomId)
            XCTAssertEqual(messageId, Inputs.messageEventId)
            switch pillTextAttachmentData.items.first {
            case .avatar(let url, _, _):
                XCTAssertEqual(url, Inputs.anotherRoomAvatarUrl)
            default:
                XCTFail("First pill item should be the avatar")
            }
        default:
            XCTFail("Pill should be of type .message")
        }
    }
    
    // Test case: a mention to a message in an unknown room
    func testPillMentionningMessageInUnknownRoom() {
        let messageWithPills = createMessageWithMentionToAnotherRoomMessage(knownRoom: false, withLabel: Inputs.messageAnotherRoomPermalink)
        let pillTextAttachment = messageWithPills.attribute(.attachment, at: messageWithPills.length - 1, effectiveRange: nil) as? PillTextAttachment
        // Pill is not highlighted.
        XCTAssert(pillTextAttachment?.data?.isHighlighted == false)
        // Attachment has correct type.
        XCTAssert(pillTextAttachment?.fileType == PillsFormatter.pillUTType)
        // Pill data contains the correct displayname and avatar url.
        XCTAssertNotNil(pillTextAttachment?.data)
        let pillTextAttachmentData: PillTextAttachmentData! = pillTextAttachment?.data
        XCTAssertEqual(pillTextAttachmentData.displayText, VectorL10n.pillMessage)
        switch pillTextAttachmentData.pillType {
        case .message(let roomId, let messageId):
            XCTAssertEqual(roomId, Inputs.anotherRoomId)
            XCTAssertEqual(messageId, Inputs.messageEventId)
            switch pillTextAttachmentData.items.first {
            case .asset(let name, _):
                XCTAssertEqual(name, "link_icon")
            default:
                XCTFail("First pill item should be the asset")
            }
        default:
            XCTFail("Pill should be of type .message")
        }
    }

    func testInsertPillInMarkdownString() {
        let message = "Hello \(Inputs.markdownLinkToBob)"
        let messageWithPills = insertPillsInMarkdownString(message)
        XCTAssertTrue(messageWithPills.attribute(.attachment, at: 6, effectiveRange: nil) is PillTextAttachment)
        let pillTextAttachment = messageWithPills.attribute(.attachment, at: 6, effectiveRange: nil) as? PillTextAttachment
        XCTAssertEqual(pillTextAttachment?.data?.displayText, Inputs.bobDisplayname)
    }

    func testInsertMultiplePillsInMarkdownString() {
        let message = "Hello \(Inputs.markdownLinkToBob) and \(Inputs.markdownLinkToAlice)"
        let messageWithPills = insertPillsInMarkdownString(message)
        let bobPillTextAttachment = messageWithPills.attribute(.attachment, at: 6, effectiveRange: nil) as? PillTextAttachment
        XCTAssertEqual(bobPillTextAttachment?.data?.displayText, Inputs.bobDisplayname)

        let alicePillTextAttachment = messageWithPills.attribute(.attachment, at: 12, effectiveRange: nil) as? PillTextAttachment
        XCTAssertEqual(alicePillTextAttachment?.data?.displayText, Inputs.aliceDisplayname)
        // No self highlight
        XCTAssert(alicePillTextAttachment?.data?.isHighlighted == false)
    }

    func testMarkdownLinkToUnknownUserIsNotPillified() {
        let message = "Hello [Unknown user](https://matrix.to/#/@unknown:matrix.org)"
        let messageWithPills = insertPillsInMarkdownString(message)
        XCTAssertFalse(messageWithPills.attribute(.attachment, at: 6, effectiveRange: nil) is PillTextAttachment)
    }

    func testMarkdownSingleLinkDetection() {
        let message = NSAttributedString(string: "Hello \(Inputs.markdownLinkToAlice)")
        let expected = [
            PillsFormatter.MarkdownLinkResult(url: URL(string: Inputs.alicePermalink)!,
                                              label: Inputs.aliceDisplayname,
                                              range: NSRange(location: 6, length: Inputs.markdownLinkToAlice.count))
        ]

        XCTAssertEqual(
            PillsFormatter.markdownLinks(in: message),
            expected
        )
    }

    func testMarkdownMultipleLinksDetection() {
        let message = NSAttributedString(string: "Hello \(Inputs.markdownLinkToAlice) and \(Inputs.markdownLinkToBob)")
        let expected = [
            PillsFormatter.MarkdownLinkResult(url: URL(string: Inputs.alicePermalink)!,
                                              label: Inputs.aliceDisplayname,
                                              range: NSRange(location: 6, length: Inputs.markdownLinkToAlice.count)),
            PillsFormatter.MarkdownLinkResult(url: URL(string: Inputs.bobPermalink)!,
                                              label: Inputs.bobDisplayname,
                                              range: NSRange(location: 6 + Inputs.markdownLinkToAlice.count + 5,
                                                             length: Inputs.markdownLinkToBob.count))
        ]

        XCTAssertEqual(
            PillsFormatter.markdownLinks(in: message),
            expected
        )
    }

    func testBrokenMarkdownLinkIsNotDetected() {
        let brokenMarkdownMessages = [
            NSAttributedString(string: "Hello [Alice](https://matrix.to/#/@alice:matrix.org"),
            NSAttributedString(string: "Hello [Alice]https://matrix.to/#/@alice:matrix.org)"),
            NSAttributedString(string: "Hello [Alice(https://matrix.to/#/@alice:matrix.org)"),
            NSAttributedString(string: "Hello Alice](https://matrix.to/#/@alice:matrix.org)"),
            NSAttributedString(string: "Hello [Alice]](https://matrix.to/#/@alice:matrix.org)"),
            NSAttributedString(string: "Hello (https://matrix.to/#/@alice:matrix.org)"),
        ]

        for message in brokenMarkdownMessages {
            XCTAssertTrue(PillsFormatter.markdownLinks(in: message).isEmpty)
        }
    }
}

@available(iOS 15.0, *)
private extension PillsFormatterTests {
    func createMessageWithMentionFromBobToAlice() -> NSAttributedString {
        let formattedMessage = NSMutableAttributedString(string: Inputs.messageStart)
        formattedMessage.append(Inputs.mentionToAlice)
        let session = FakeMXSession(myUserId: Inputs.aliceMember.userId)
        let messageWithPills = PillsFormatter.insertPills(in: formattedMessage,
                                                          withSession: session,
                                                          eventFormatter: EventFormatter(matrixSession: session),
                                                          event: FakeMXEvent(sender: Inputs.bobMember.userId),
                                                          roomState: FakeMXRoomState(roomMembers: FakeMXRoomMembers()),
                                                          andLatestRoomState: nil)
        return messageWithPills
    }
    
    func createMessageWithMentionFromBobToAnotherUser(withLinkText: Bool = false) -> NSAttributedString {
        let formattedMessage = NSMutableAttributedString(string: Inputs.messageStart)
        if withLinkText {
            formattedMessage.append(Inputs.mentionToAnotherUserWithLabel)
        } else {
            formattedMessage.append(Inputs.mentionToAnotherUser)
        }
        
        let session = FakeMXSession(myUserId: Inputs.aliceMember.userId)
        let messageWithPills = PillsFormatter.insertPills(in: formattedMessage,
                                                          withSession: session,
                                                          eventFormatter: EventFormatter(matrixSession: session),
                                                          event: FakeMXEvent(sender: Inputs.anotherUserId),
                                                          roomState: FakeMXRoomState(roomMembers: FakeMXRoomMembers()),
                                                          andLatestRoomState: nil)
        return messageWithPills
    }

    func createMessageWithMentionFromBobToAliceWithLatestRoomState() -> NSAttributedString {
        let formattedMessage = NSMutableAttributedString(string: Inputs.messageStart)
        formattedMessage.append(Inputs.mentionToAlice)
        let session = FakeMXSession(myUserId: Inputs.aliceMember.userId)
        let messageWithPills = PillsFormatter.insertPills(in: formattedMessage,
                                                          withSession: session,
                                                          eventFormatter: EventFormatter(matrixSession: session),
                                                          event: FakeMXEvent(sender: Inputs.bobMember.userId),
                                                          roomState: FakeMXRoomState(roomMembers: FakeMXRoomMembers()),
                                                          andLatestRoomState: FakeMXRoomState(roomMembers: FakeMXUpdatedRoomMembers()))
        return messageWithPills
    }
    
    func createMessageWithMentionToRoom(isSpace: Bool = false, knownRoom: Bool = true, usingAlias: Bool = false, withLinkText: String? = nil) -> NSAttributedString {
        let formattedMessage = NSMutableAttributedString(string: Inputs.messageStart)
        let mention: NSAttributedString
        if usingAlias {
            mention = NSAttributedString(string: withLinkText ?? Inputs.roomAliasPermalink , attributes: [.link: URL(string: Inputs.roomAliasPermalink)!])
        } else {
            mention = NSAttributedString(string: withLinkText ?? Inputs.roomPermalink , attributes: [.link: URL(string: Inputs.roomPermalink)!])
        }
        formattedMessage.append(mention)
        let session = FakeMXSession(myUserId: Inputs.aliceMember.userId)
        let event = FakeMXEvent(eventId: Inputs.messageEventId, sender: Inputs.bobMember.userId)
        session.store = FakeMXStore(withEvents: [event])
        if knownRoom {
            let room = FakeMXRoom(roomId: Inputs.roomId, matrixSession: session, andStore: nil)!
            let roomSummary = FakeMXRoomSummary(roomId: Inputs.roomId,
                                                displayName: Inputs.roomDisplayName,
                                                alias: Inputs.roomAlias,
                                                avatar: Inputs.roomAvatarUrl,
                                                matrixSession: session)
            if isSpace {
                roomSummary.roomType = .space
            }
            session.addFakeRoom(room)
            session.addFakeRoomSummary(roomSummary)
        }
        
        let messageWithPills = PillsFormatter.insertPills(in: formattedMessage,
                                                          withSession: session,
                                                          eventFormatter: EventFormatter(matrixSession: session),
                                                          event: event,
                                                          roomState: FakeMXRoomState(roomMembers: FakeMXRoomMembers()),
                                                          andLatestRoomState: nil)
        return messageWithPills
    }
    
    func createMessageWithMentionToMessage(from sender: MXRoomMember, withLabel string: String) -> NSAttributedString {
        let formattedMessage = NSMutableAttributedString(string: Inputs.messageStart)
        formattedMessage.append(NSAttributedString(string: string, attributes: [.link: URL(string: Inputs.messagePermalink)!]))
        let session = FakeMXSession(myUserId: Inputs.aliceMember.userId)
        let event = FakeMXEvent(eventId: Inputs.messageEventId, sender: sender.userId)
        session.store = FakeMXStore(withEvents: [event])
        let room = FakeMXRoom(roomId: Inputs.roomId, matrixSession: session, andStore: nil)!
        let roomSummary = FakeMXRoomSummary(roomId: Inputs.roomId,
                                            displayName: Inputs.roomDisplayName,
                                            alias: Inputs.roomAlias,
                                            avatar: Inputs.roomAvatarUrl,
                                            matrixSession: session)
        session.addFakeRoom(room)
        session.addFakeRoomSummary(roomSummary)

        
        let messageWithPills = PillsFormatter.insertPills(in: formattedMessage,
                                                          withSession: session,
                                                          eventFormatter: EventFormatter(matrixSession: session),
                                                          event: event,
                                                          roomState: FakeMXRoomState(roomMembers: FakeMXRoomMembers(), roomId: Inputs.roomId),
                                                          andLatestRoomState: nil)
        return messageWithPills
    }
    
    func createMessageWithMentionToMessage(sentBy senderId: String, withLabel string: String) -> NSAttributedString {
        let formattedMessage = NSMutableAttributedString(string: Inputs.messageStart)
        formattedMessage.append(NSAttributedString(string: string, attributes: [.link: URL(string: Inputs.messagePermalink)!]))
        let session = FakeMXSession(myUserId: Inputs.aliceMember.userId)
        let event = FakeMXEvent(eventId: Inputs.messageEventId, sender: senderId)
        session.store = FakeMXStore(withEvents: [event])
        let room = FakeMXRoom(roomId: Inputs.roomId, matrixSession: session, andStore: nil)!
        let roomSummary = FakeMXRoomSummary(roomId: Inputs.roomId,
                                            displayName: Inputs.roomDisplayName,
                                            alias: Inputs.roomAlias,
                                            avatar: Inputs.roomAvatarUrl,
                                            matrixSession: session)
        session.addFakeRoom(room)
        session.addFakeRoomSummary(roomSummary)

        
        let messageWithPills = PillsFormatter.insertPills(in: formattedMessage,
                                                          withSession: session,
                                                          eventFormatter: EventFormatter(matrixSession: session),
                                                          event: event,
                                                          roomState: FakeMXRoomState(roomMembers: FakeMXRoomMembers(), roomId: Inputs.roomId),
                                                          andLatestRoomState: nil)
        return messageWithPills
    }
    
    func createMessageWithMentionToAnotherRoomMessage(knownRoom: Bool, withLabel string: String) -> NSAttributedString {
        let formattedMessage = NSMutableAttributedString(string: Inputs.messageStart)
        formattedMessage.append(NSAttributedString(string: string, attributes: [.link: URL(string: Inputs.messageAnotherRoomPermalink)!]))
        let session = FakeMXSession(myUserId: Inputs.aliceMember.userId)
        let event = FakeMXEvent(eventId: Inputs.messageEventId, sender: Inputs.anotherUserId)
        session.store = FakeMXStore(withEvents: [event])
        if knownRoom {
            let room = FakeMXRoom(roomId: Inputs.anotherRoomId, matrixSession: session, andStore: nil)!
            let roomSummary = FakeMXRoomSummary(roomId: Inputs.anotherRoomId,
                                                displayName: Inputs.anotherRoomDisplayName,
                                                alias: nil,
                                                avatar: Inputs.anotherRoomAvatarUrl,
                                                matrixSession: session)
            session.addFakeRoom(room)
            session.addFakeRoomSummary(roomSummary)
        }
        
        let messageWithPills = PillsFormatter.insertPills(in: formattedMessage,
                                                          withSession: session,
                                                          eventFormatter: EventFormatter(matrixSession: session),
                                                          event: event,
                                                          roomState: FakeMXRoomState(roomMembers: FakeMXRoomMembers(), roomId: Inputs.roomId),
                                                          andLatestRoomState: nil)
        return messageWithPills
    }

    private func insertPillsInMarkdownString(_ markdownString: String) -> NSAttributedString {
        let message = NSAttributedString(string: markdownString)
        let session = FakeMXSession(myUserId: Inputs.aliceUserId)
        return PillsFormatter.insertPills(in: message,
                                          withSession: session,
                                          eventFormatter: EventFormatter(matrixSession: session),
                                          roomState: FakeMXRoomState(roomMembers: FakeMXRoomMembers()),
                                          font: UIFont.systemFont(ofSize: 15.0))
    }
}

// MARK: - Mock objects
private class FakeMXSession: MXSession {
    private var mockMyUserId: String
    private var mockRooms: [FakeMXRoom] = []
    private var mockRoomSummaries: [String: FakeMXRoomSummary] = [:]
    private var mockStore: FakeMXStore?
    
    init(myUserId: String) {
        mockMyUserId = myUserId
        let credentials = MXCredentials(homeServer: "mock_home_server",
                                        userId: "mock_user_id",
                                        accessToken: "mock_access_token")
        let client = MXRestClient(credentials: credentials)
        super.init(matrixRestClient: client)
    }

    override var myUserId: String! {
        return mockMyUserId
    }
    
    func addFakeRoom(_ room: FakeMXRoom) {
        mockRooms.append(room)
    }
        
    override func room(withRoomId roomId: String!) -> MXRoom! {
        return mockRooms.first(where: { $0.roomId == roomId })
    }
    
    override func room(withAlias roomAlias: String) -> MXRoom? {
        for (roomId, summary) in mockRoomSummaries {
            if summary.aliases.contains(roomAlias) {
                return room(withRoomId: roomId)
            }
        }
        return nil
    }
    
    override func roomSummary(withRoomId roomId: String!) -> MXRoomSummary? {
        return mockRoomSummaries[roomId]
    }
    
    func addFakeRoomSummary(_ roomSummary: FakeMXRoomSummary) {
        self.mockRoomSummaries[roomSummary.roomId] = roomSummary
    }
    
    override var store: MXStore! {
        get { return mockStore }
        set { mockStore = newValue as? FakeMXStore }
    }
}

private class FakeMXStore: MXMemoryStore {
    private var mockEvents: [MXEvent]
    
    init(withEvents events: [MXEvent]) {
        self.mockEvents = events
        super.init()
    }
    
    override func event(withEventId eventId: String, inRoom roomId: String) -> MXEvent? {
        return mockEvents.first(where: { $0.eventId == eventId })
    }
}

private class FakeMXRoom: MXRoom {
    private var mockDisplayName: String? = nil
    
    override init() {
        super.init()
    }
    
    override init!(roomId: String!, matrixSession mxSession: MXSession!, andStore store: MXStore!) {
        super.init(roomId: roomId, matrixSession: mxSession, andStore: store)
    }
    
    override var summary: MXRoomSummary! {
        return mxSession?.roomSummary(withRoomId: self.roomId)
    }
}

private class FakeMXRoomSummary: MXRoomSummary {
    private var mockDisplayName: String?
    private var mockAliases: [String]?
    private var mockAvatar: String? = nil

    override init() {
        super.init()
    }
    
    init(roomId: String, displayName: String, alias: String?, avatar: String?, matrixSession mxSession: MXSession) {
        super.init(roomId: roomId, andMatrixSession: mxSession)
        self.mockDisplayName = displayName
        self.mockAliases = alias.flatMap { [$0] } ?? []
        self.mockAvatar = avatar
    }
    
    override init!(roomId: String!, matrixSession mxSession: MXSession!, andStore store: MXStore!) {
        super.init(roomId: roomId, matrixSession: mxSession, andStore: store)
    }
    
    override init!(roomId: String!, andMatrixSession mxSession: MXSession!) {
        super.init(roomId: roomId, andMatrixSession: mxSession)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override var displayName: String! {
        get { return mockDisplayName }
        set { mockDisplayName = newValue }
    }
    
    override var avatar: String! {
        get { return mockAvatar }
        set { mockAvatar = newValue }
    }
    
    override var aliases: [String]! {
        get { return mockAliases }
        set { mockAliases = newValue }
    }
}

private class FakeMXRoomState: MXRoomState {
    private let mockRoomMembers: MXRoomMembers
    private let mockRoomId: String?

    init(roomMembers: MXRoomMembers) {
        mockRoomMembers = roomMembers
        mockRoomId = nil

        super.init()
    }
    
    init(roomMembers: MXRoomMembers, roomId: String) {
        mockRoomMembers = roomMembers
        mockRoomId = roomId
        
        super.init()
    }

    override var members: MXRoomMembers! {
        return mockRoomMembers
    }
    
    override var roomId: String! {
        return mockRoomId
    }
}

private class FakeMXUpdatedRoomMembers: MXRoomMembers {
    override var members: [MXRoomMember]! {
        return [Inputs.aliceMemberAway, Inputs.bobMember]
    }

    override func member(withUserId userId: String!) -> MXRoomMember! {
        return members.first(where: { $0.userId == userId })
    }
}

private class FakeMXRoomMembers: MXRoomMembers {
    override var members: [MXRoomMember]! {
        return [Inputs.aliceMember, Inputs.bobMember]
    }

    override func member(withUserId userId: String!) -> MXRoomMember! {
        return members.first(where: { $0.userId == userId })
    }
}

private class FakeMXRoomMember: MXRoomMember {
    private let mockDisplayname: String
    private var mockAvatarUrl: String
    private let mockUserId: String

    init(displayname: String, avatarUrl: String, userId: String) {
        mockDisplayname = displayname
        mockAvatarUrl = avatarUrl
        mockUserId = userId

        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override var displayname: String! {
        return mockDisplayname
    }

    override var avatarUrl: String! {
        get { return mockAvatarUrl }
        set { mockAvatarUrl = newValue }
    }

    override var userId: String! {
        return mockUserId
    }
}

private class FakeMXEvent: MXEvent {
    private var mockSender: String
    private var mockEventId: String?

    init(sender: String) {
        mockSender = sender
        mockEventId = nil

        super.init()
    }
    
    init(eventId: String, sender: String) {
        mockEventId = eventId
        mockSender = sender
        
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override var sender: String! {
        get { return mockSender }
        set { mockSender = newValue }
    }
    
    override var eventId: String! {
        get { return mockEventId }
        set { mockEventId = newValue }
    }
}
