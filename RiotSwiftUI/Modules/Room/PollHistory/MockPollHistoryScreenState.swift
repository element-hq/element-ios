//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import SwiftUI

/// Using an enum for the screen allows you define the different state cases with
/// the relevant associated data for each case.
enum MockPollHistoryScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case active
    case past
    case activeNoMoreContent
    case contentLoading
    case empty
    case emptyLoading
    case emptyNoMoreContent
    case loading
    
    /// The associated screen
    var screenType: Any.Type {
        PollHistory.self
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView) {
        var pollHistoryMode: PollHistoryMode = .active
        let pollService = MockPollHistoryService()
        
        switch self {
        case .active:
            pollHistoryMode = .active
        case .activeNoMoreContent:
            pollHistoryMode = .active
            pollService.hasNextBatch = false
        case .past:
            pollHistoryMode = .past
        case .contentLoading:
            pollService.nextBatchPublishers.append(MockPollPublisher.loadingPolls)
        case .empty:
            pollHistoryMode = .active
            pollService.nextBatchPublishers = [MockPollPublisher.emptyPolls]
        case .emptyLoading:
            pollService.nextBatchPublishers = [MockPollPublisher.emptyPolls, MockPollPublisher.loadingPolls]
        case .emptyNoMoreContent:
            pollService.hasNextBatch = false
            pollService.nextBatchPublishers = [MockPollPublisher.emptyPolls]
        case .loading:
            pollService.nextBatchPublishers = [MockPollPublisher.loadingPolls]
        }
        
        let viewModel = PollHistoryViewModel(mode: pollHistoryMode, pollService: pollService)
        
        // can simulate service and viewModel actions here if needs be.
        switch self {
        case .contentLoading, .emptyLoading:
            viewModel.process(viewAction: .loadMoreContent)
        default:
            break
        }
        
        return (
            [pollHistoryMode, viewModel],
            AnyView(PollHistory(viewModel: viewModel.context)
                .environmentObject(AvatarViewModel.withMockedServices()))
        )
    }
}

enum MockPollPublisher {
    static var emptyPolls: AnyPublisher<TimelinePollDetails, Error> {
        Empty<TimelinePollDetails, Error>(completeImmediately: true).eraseToAnyPublisher()
    }
    
    static var loadingPolls: AnyPublisher<TimelinePollDetails, Error> {
        Empty<TimelinePollDetails, Error>(completeImmediately: false).eraseToAnyPublisher()
    }
    
    static var failure: AnyPublisher<TimelinePollDetails, Error> {
        Fail(error: NSError(domain: "fake", code: 1)).eraseToAnyPublisher()
    }
}
