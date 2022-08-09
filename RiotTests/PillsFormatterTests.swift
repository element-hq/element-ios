// 
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
    static let bobMember = FakeMXRoomMember(displayname: "Bob", avatarUrl: "", userId: "@bob:matrix.org")
    static let alicePermalink = "https://matrix.to/#/@alice:matrix.org"
    static let mentionToAlice = NSAttributedString(string: aliceDisplayname, attributes: [.link: URL(string: alicePermalink)!])
    static let markdownLinkToAlice = "[Alice](\(alicePermalink))"
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
        XCTAssertEqual(pillTextAttachment?.data?.displayText, Inputs.aliceDisplayname)
        XCTAssertEqual(pillTextAttachment?.data?.avatarUrl, Inputs.aliceAvatarUrl)
        // Pill has expected size.
        let expectedSize = PillAttachmentViewProvider.size(forDisplayText: pillTextAttachment!.data!.displayText,
                                                           andFont: pillTextAttachment!.data!.font)
        XCTAssertEqual(pillTextAttachment?.bounds.size, expectedSize)

        PillsFormatter.refreshPills(in: messageWithPills,
                                    with: FakeMXRoomState(roomMembers: FakeMXUpdatedRoomMembers()))
        let refreshedPillTextAttachment = messageWithPills.attribute(.attachment, at: messageWithPills.length - 1, effectiveRange: nil) as? PillTextAttachment
        // Alice's pill is still highlighted.
        XCTAssert(pillTextAttachment?.data?.isHighlighted == true)
        // Pill data is refreshed with correct data.
        XCTAssertEqual(refreshedPillTextAttachment?.data?.displayText, Inputs.aliceAwayDisplayname)
        XCTAssertEqual(refreshedPillTextAttachment?.data?.avatarUrl, Inputs.aliceNewAvatarUrl)
        // Pill size is updated
        let newExpectedSize = PillAttachmentViewProvider.size(forDisplayText: refreshedPillTextAttachment!.data!.displayText,
                                                              andFont: refreshedPillTextAttachment!.data!.font)
        XCTAssertEqual(refreshedPillTextAttachment?.bounds.size, newExpectedSize)
    }

    func testPillsUsingLatestRoomState() {
        let messageWithPills = createMessageWithMentionFromBobToAliceWithLatestRoomState()
        let pillTextAttachment = messageWithPills.attribute(.attachment, at: messageWithPills.length - 1, effectiveRange: nil) as? PillTextAttachment
        // Pill uses the latest room state data.
        XCTAssertEqual(pillTextAttachment?.data?.displayText, Inputs.aliceAwayDisplayname)
        XCTAssertEqual(pillTextAttachment?.data?.avatarUrl, Inputs.aliceNewAvatarUrl)
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
}

// MARK: - Mock objects
private class FakeMXSession: MXSession {
    private var mockMyUserId: String

    init(myUserId: String) {
        mockMyUserId = myUserId

        super.init()
    }

    override var myUserId: String! {
        return mockMyUserId
    }
}

private class FakeMXRoomState: MXRoomState {
    private let mockRoomMembers: MXRoomMembers

    init(roomMembers: MXRoomMembers) {
        mockRoomMembers = roomMembers

        super.init()
    }

    override var members: MXRoomMembers! {
        return mockRoomMembers
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

    init(sender: String) {
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
}
