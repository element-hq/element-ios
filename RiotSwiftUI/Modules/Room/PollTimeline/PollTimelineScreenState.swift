// File created from SimpleUserProfileExample
// $ createScreen.sh Room/UserSuggestion UserSuggestion
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

@available(iOS 14.0, *)
enum MockPollTimelineScreenState: MockScreenState, CaseIterable {
    case open
    case closed
    
    var screenType: Any.Type {
        MockPollTimelineScreenState.self
    }
    
    var screenView: ([Any], AnyView)  {
        let answerOptions = [TimelineAnswerOption(id: "1", text: "First", count: 10, winner: false, selected: false),
        TimelineAnswerOption(id: "2", text: "Second", count: 5, winner: false, selected: true),
        TimelineAnswerOption(id: "3", text: "Third", count: 15, winner: true, selected: false)]
        
        let poll = TimelinePoll(question: "Question",
        answerOptions: answerOptions,
        closed: (self == .closed ? true : false),
        totalAnswerCount: 20,
        type: .disclosed,
        maxAllowedSelections: 1)
        
        let viewModel = PollTimelineViewModel(timelinePoll: poll)
        
        return ([viewModel], AnyView(PollTimelineView(viewModel: viewModel.context)))
    }
}
