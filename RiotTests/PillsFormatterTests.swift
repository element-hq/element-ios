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
@testable import Riot

// MARK: - Inputs
private enum Inputs {
    static let messageStart = "Hello "
    static let aliceDisplayname = "Alice"
    static let aliceMember = FakeMXRoomMember(displayname: aliceDisplayname, avatarUrl: "", userId: "@alice:matrix.org")
    static let bobMember = FakeMXRoomMember(displayname: "Bob", avatarUrl: "", userId: "@bob:matrix.org")
    static let alicePermalink = "https://matrix.to/#/@alice:matrix.org"
    static let mentionToAlice = NSAttributedString(string: aliceDisplayname, attributes: [.link: URL(string: alicePermalink)!])
    static let markdownLinkToAlice = "[Alice](\(alicePermalink))"
}

// MARK: - Tests
@available(iOS 15.0, *)
class PillsFormatterTests: XCTestCase {
    func testPillsInsertion() {
        let messageWithPills = createMessageWithMentionFromBobToAlice()
        XCTAssertEqual(messageWithPills.length, Inputs.messageStart.count + 1) // +1 non-unicode character for the pill/textAttachment
        XCTAssert(messageWithPills.attribute(.attachment, at: messageWithPills.length - 1, effectiveRange: nil) is PillTextAttachment)

        let pillTextAttachment = messageWithPills.attribute(.attachment, at: messageWithPills.length - 1, effectiveRange: nil) as? PillTextAttachment
        XCTAssert(pillTextAttachment?.data?.isHighlighted == true) // Alice is highlighted
        XCTAssert(pillTextAttachment?.fileType == PillsFormatter.pillUTType)
    }

    func testPillsToMarkdown() {
        let messageWithPills = createMessageWithMentionFromBobToAlice()
        let markdownMessage = PillsFormatter.stringByReplacingPills(in: messageWithPills, asMarkdown: true)
        XCTAssertEqual(markdownMessage, Inputs.messageStart + Inputs.markdownLinkToAlice)
    }

    func testPillsToRawBody() {
        let messageWithPills = createMessageWithMentionFromBobToAlice()
        let rawMessage = PillsFormatter.stringByReplacingPills(in: messageWithPills, asMarkdown: false)
        XCTAssertEqual(rawMessage, Inputs.messageStart + Inputs.aliceDisplayname)
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
                                                          andRoomState: FakeMXRoomState())
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
    override var members: MXRoomMembers! {
        return FakeMXRoomMembers()
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
    private var mockDisplayname: String
    private var mockAvatarUrl: String
    private var mockUserId: String

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
