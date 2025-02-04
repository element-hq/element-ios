//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import RiotSwiftUI
import XCTest

final class PollHistoryViewModelTests: XCTestCase {
    private var viewModel: PollHistoryViewModel!
    private var pollHistoryService: MockPollHistoryService = .init()

    override func setUpWithError() throws {
        pollHistoryService = .init()
        viewModel = .init(mode: .active, pollService: pollHistoryService)
    }

    func testEmitsContentOnLanding() throws {
        XCTAssert(viewModel.state.polls == nil)
        viewModel.process(viewAction: .viewAppeared)
        XCTAssertFalse(try polls.isEmpty)
    }
    
    func testLoadingState() throws {
        XCTAssertFalse(viewModel.state.isLoading)
        viewModel.process(viewAction: .viewAppeared)
        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertFalse(try polls.isEmpty)
    }
    
    func testLoadingStateIsTrueWhileLoading() {
        XCTAssertFalse(viewModel.state.isLoading)
        pollHistoryService.nextBatchPublishers = [MockPollPublisher.loadingPolls, MockPollPublisher.emptyPolls]
        viewModel.process(viewAction: .viewAppeared)
        XCTAssertTrue(viewModel.state.isLoading)
        viewModel.process(viewAction: .viewAppeared)
        XCTAssertFalse(viewModel.state.isLoading)
    }
    
    func testUpdatesAreHandled() throws {
        let mockUpdates: PassthroughSubject<TimelinePollDetails, Never> = .init()
        pollHistoryService.updatesPublisher = mockUpdates.eraseToAnyPublisher()
        viewModel.process(viewAction: .viewAppeared)
        
        var firstPoll = try XCTUnwrap(try polls.first)
        XCTAssertEqual(firstPoll.question, "Do you like the active poll number 1?")
        firstPoll.question = "foo"
        
        mockUpdates.send(firstPoll)
        
        let updatedPoll = try XCTUnwrap(viewModel.state.polls?.first)
        XCTAssertEqual(updatedPoll.question, "foo")
    }
    
    func testSegmentsAreUpdated() throws {
        viewModel.process(viewAction: .viewAppeared)
        XCTAssertFalse(try polls.isEmpty)
        XCTAssertTrue(try polls.allSatisfy { !$0.closed })
        
        viewModel.state.bindings.mode = .past
        viewModel.process(viewAction: .segmentDidChange)
        
        XCTAssertTrue(try polls.allSatisfy(\.closed))
    }
    
    func testPollsAreReverseOrdered() throws {
        viewModel.process(viewAction: .viewAppeared)
        
        let pollDates = try polls.map(\.startDate)
        XCTAssertEqual(pollDates, pollDates.sorted(by: { $0 > $1 }))
    }
    
    func testLivePollsAreHandled() throws {
        pollHistoryService.nextBatchPublishers = [MockPollPublisher.emptyPolls]
        pollHistoryService.livePollsPublisher = Just(mockPoll).eraseToAnyPublisher()
        viewModel.process(viewAction: .viewAppeared)
        XCTAssertEqual(viewModel.state.polls?.count, 1)
        XCTAssertEqual(viewModel.state.polls?.first?.id, "id")
    }
    
    func testLivePollsDontChangeLoadingState() throws {
        let livePolls = PassthroughSubject<TimelinePollDetails, Never>()
        pollHistoryService.nextBatchPublishers = [MockPollPublisher.loadingPolls]
        pollHistoryService.livePollsPublisher = livePolls.eraseToAnyPublisher()
        viewModel.process(viewAction: .viewAppeared)
        XCTAssertTrue(viewModel.state.isLoading)
        XCTAssertNil(viewModel.state.polls)
        livePolls.send(mockPoll)
        XCTAssertTrue(viewModel.state.isLoading)
        XCTAssertNotNil(viewModel.state.polls)
        XCTAssertEqual(viewModel.state.polls?.count, 1)
    }
    
    func testAfterFailureCompletionIsCalled() throws {
        pollHistoryService.nextBatchPublishers = [MockPollPublisher.failure]
        viewModel.process(viewAction: .viewAppeared)
        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertNotNil(viewModel.state.polls)
        XCTAssertNotNil(viewModel.state.bindings.alertInfo)
    }
}

private extension PollHistoryViewModelTests {
    var polls: [TimelinePollDetails] {
        get throws {
            try XCTUnwrap(viewModel.state.polls)
        }
    }
    
    var mockPoll: TimelinePollDetails {
        .init(id: "id",
              question: "Do you like polls?",
              answerOptions: [],
              closed: false,
              startDate: .init(),
              totalAnswerCount: 3,
              type: .undisclosed,
              eventType: .started,
              maxAllowedSelections: 1,
              hasBeenEdited: false,
              hasDecryptionError: false)
    }
}
