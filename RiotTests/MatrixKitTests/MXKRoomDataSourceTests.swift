/*
Copyright 2024 New Vector Ltd.
Copyright 2021 The Matrix.org Foundation C.I.C

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation
import XCTest

@testable import Element

class MXKRoomDataSourceTests: XCTestCase {

    // MARK: - Destruction tests

    func testDestroyRemovesAllBubbles() {
        let dataSource = StubMXKRoomDataSource()
        dataSource.destroy()
        XCTAssert(dataSource.getBubbles()?.isEmpty != false)
    }

    func testDestroyDeallocatesAllBubbles() throws {
        let dataSource = StubMXKRoomDataSource()
        weak var first = try XCTUnwrap(dataSource.getBubbles()?.first)
        weak var last = try XCTUnwrap(dataSource.getBubbles()?.last)
        dataSource.destroy()
        XCTAssertNil(first)
        XCTAssertNil(last)
    }

    // MARK: - Collapsing tests

    func testCollapseBubblesWhenProcessingTogether() throws {
        let dataSource = try FakeMXKRoomDataSource.make()
        try dataSource.queueEvent1()
        try dataSource.queueEvent2()
        awaitEventProcessing(for: dataSource)
        dataSource.verifyCollapsedEvents(2)
    }

    func testCollapseBubblesWhenProcessingAlone() throws {
        let dataSource = try FakeMXKRoomDataSource.make()
        try dataSource.queueEvent1()
        awaitEventProcessing(for: dataSource)
        try dataSource.queueEvent2()
        awaitEventProcessing(for: dataSource)
        dataSource.verifyCollapsedEvents(2)
    }

    private func awaitEventProcessing(for dataSource: MXKRoomDataSource) {
        let e = expectation(description: "The wai-ai-ting is the hardest part")
        dataSource.processQueuedEvents { _, _ in
            e.fulfill()
        }
        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }

}

// MARK: - Test doubles

private final class StubMXKRoomDataSource: MXKRoomDataSource {

    override init() {
        super.init()

        let data1 = MXKRoomBubbleCellData()
        let data2 = MXKRoomBubbleCellData()
        let data3 = MXKRoomBubbleCellData()

        data1.nextCollapsableCellData = data2
        data2.prevCollapsableCellData = data1
        data2.nextCollapsableCellData = data3
        data3.prevCollapsableCellData = data2

        replaceBubbles([data1, data2, data3])
    }

}

private final class FakeMXKRoomDataSource: MXKRoomDataSource {

    class func make() throws -> FakeMXKRoomDataSource {
        let dataSource = try XCTUnwrap(FakeMXKRoomDataSource(roomId: "!foofoofoofoofoofoo:matrix.org", andMatrixSession: nil, threadId: nil))
        dataSource.registerCellDataClass(CollapsibleBubbleCellData.self, forCellIdentifier: kMXKRoomBubbleCellDataIdentifier)
        dataSource.eventFormatter = CountingEventFormatter(matrixSession: nil)
        return dataSource
    }

    override var state: MXKDataSourceState {
        MXKDataSourceStateReady
    }

    override var roomState: MXRoomState! {
        nil
    }

    func queueEvent1() throws {
        try queueEvent(json: #"{"sender":"@alice:matrix.org","content":{"displayname":"bob","membership":"invite"},"origin_server_ts":1616488993287,"state_key":"@bob:matrix.org","room_id":"!foofoofoofoofoofoo:matrix.org","event_id":"$lGK3budX5w009ErtQwE9ZFhwyUUAV9DqEN5yb2fI4Do","type":"m.room.member","unsigned":{"age":1204610,"prev_sender":"@alice:matrix.org","prev_content":{"membership":"leave"},"replaces_state":"$9mQ6RtscXqHCxWqOElI-eP_kwpkuPd2Czm3UHviGoyE"}}"#)
    }

    func queueEvent2() throws {
        try queueEvent(json: #"{"sender":"@alice:matrix.org","content":{"displayname":"john","membership":"invite"},"origin_server_ts":1616488967295,"state_key":"@john:matrix.org","room_id":"!foofoofoofoofoofoo:matrix.org","event_id":"$-00slfAluxVTP2VWytgDThTmh3nLd0WJD6gzBo2scJM","type":"m.room.member","unsigned":{"age":1712006,"prev_sender":"@alice:matrix.org","prev_content":{"membership":"leave"},"replaces_state":"$NRNkCMKeKK5NtTfWkMfTlMr5Ygw60Q2CQYnJNkbzyrs"}}"#)
    }

    private func queueEvent(json: String) throws {
        let data = try XCTUnwrap(json.data(using: .utf8))
        let dict = try XCTUnwrap((try JSONSerialization.jsonObject(with: data, options: [])) as? [AnyHashable: Any])
        let event = MXEvent(fromJSON: dict)
        queueEvent(forProcessing: event, with: nil, direction: .forwards)
    }

    func verifyCollapsedEvents(_ number: Int) {
        let message = getBubbles()?.first?.collapsedAttributedTextMessage.string
        XCTAssertEqual(message, "\(number)")
    }

}

private final class CollapsibleBubbleCellData: MXKRoomBubbleCellData {

    override init() {
        super.init()
    }

    required init!(event: MXEvent!, andRoomState roomState: MXRoomState!, andRoomDataSource roomDataSource: MXKRoomDataSource!) {
        super.init(event: event, andRoomState: roomState, andRoomDataSource: roomDataSource)
        collapsable = true
    }

    override func collapse(with cellData: MXKRoomBubbleCellDataStoring!) -> Bool {
        true
    }

}

private final class CountingEventFormatter: MXKEventFormatter {

    override func attributedString(from events: [MXEvent]!,
                                   with roomState: MXRoomState!,
                                   andLatestRoomState latestRoomState: MXRoomState!,
                                   error: UnsafeMutablePointer<MXKEventFormatterError>!) -> NSAttributedString! {
        NSAttributedString(string: "\(events.count)")
    }
}
