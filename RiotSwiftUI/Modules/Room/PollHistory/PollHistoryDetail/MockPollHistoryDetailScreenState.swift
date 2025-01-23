//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

enum MockPollHistoryDetailScreenState: MockScreenState, CaseIterable {
    case openDisclosed
    case closedDisclosed
    case openUndisclosed
    case closedUndisclosed
    case closedPollEnded
    
    var screenType: Any.Type {
        PollHistoryDetail.self
    }
    
    var poll: TimelinePollDetails {
        let answerOptions = [TimelinePollAnswerOption(id: "1", text: "First", count: 10, winner: false, selected: false),
                             TimelinePollAnswerOption(id: "2", text: "Second", count: 5, winner: false, selected: true),
                             TimelinePollAnswerOption(id: "3", text: "Third", count: 15, winner: true, selected: false)]
        
        let poll = TimelinePollDetails(id: "id",
                                       question: "Question",
                                       answerOptions: answerOptions,
                                       closed: self == .closedDisclosed || self == .closedUndisclosed ? true : false,
                                       startDate: .init(timeIntervalSinceReferenceDate: 0),
                                       totalAnswerCount: 20,
                                       type: self == .closedDisclosed || self == .openDisclosed ? .disclosed : .undisclosed,
                                       eventType: self == .closedPollEnded ? .ended : .started,
                                       maxAllowedSelections: 1,
                                       hasBeenEdited: false,
                                       hasDecryptionError: false)
        return poll
    }
    
    var screenView: ([Any], AnyView) {
        let timelineViewModel = TimelinePollViewModel(timelinePollDetailsState: .loaded(poll))
        let viewModel = PollHistoryDetailViewModel(poll: poll)
        
        return ([viewModel], AnyView(PollHistoryDetail(viewModel: viewModel.context, contentPoll: TimelinePollView(viewModel: timelineViewModel.context))))
    }
}
