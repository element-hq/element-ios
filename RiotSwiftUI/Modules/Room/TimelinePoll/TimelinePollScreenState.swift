//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

enum MockTimelinePollScreenState: MockScreenState, CaseIterable {
    case openDisclosed
    case closedDisclosed
    case openUndisclosed
    case closedUndisclosed
    case closedPollEnded
    case loading
    case invalidStartEvent
    case withAlert
    
    var screenType: Any.Type {
        TimelinePollDetails.self
    }
    
    var screenView: ([Any], AnyView) {
        let answerOptions = [TimelinePollAnswerOption(id: "1", text: "First", count: 10, winner: false, selected: false),
                             TimelinePollAnswerOption(id: "2", text: "Second", count: 5, winner: false, selected: true),
                             TimelinePollAnswerOption(id: "3", text: "Third", count: 15, winner: true, selected: false)]
        
        let poll = TimelinePollDetails(id: "id",
                                       question: "Question",
                                       answerOptions: answerOptions,
                                       closed: self == .closedDisclosed || self == .closedUndisclosed ? true : false,
                                       startDate: .init(),
                                       totalAnswerCount: 20,
                                       type: self == .closedDisclosed || self == .openDisclosed ? .disclosed : .undisclosed,
                                       eventType: self == .closedPollEnded ? .ended : .started,
                                       maxAllowedSelections: 1,
                                       hasBeenEdited: false,
                                       hasDecryptionError: false)
        
        let viewModel: TimelinePollViewModel
        
        switch self {
        case .loading:
            viewModel = TimelinePollViewModel(timelinePollDetailsState: .loading)
        case .invalidStartEvent:
            viewModel = TimelinePollViewModel(timelinePollDetailsState: .errored)
        default:
            viewModel = TimelinePollViewModel(timelinePollDetailsState: .loaded(poll))
        }
        
        if self == .withAlert {
            viewModel.showAnsweringFailure()
        }
        
        return ([viewModel], AnyView(TimelinePollView(viewModel: viewModel.context)))
    }
}
