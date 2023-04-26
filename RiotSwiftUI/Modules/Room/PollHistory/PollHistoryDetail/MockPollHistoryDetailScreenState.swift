//
// Copyright 2021 New Vector Ltd
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
