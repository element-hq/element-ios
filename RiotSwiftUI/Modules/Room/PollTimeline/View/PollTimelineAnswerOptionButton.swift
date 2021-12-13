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

import SwiftUI

@available(iOS 14.0, *)
struct PollTimelineAnswerOptionButton: View {
    
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    let answerOption: TimelineAnswerOption
    let pollClosed: Bool
    let showResults: Bool
    let totalAnswerCount: UInt
    let action: () -> Void
    
    // MARK: Public
    
    var body: some View {
        Button(action: action) {
            let rect = RoundedRectangle(cornerRadius: 4.0)
            answerOptionLabel
                .padding(.horizontal, 8.0)
                .padding(.top, 12.0)
                .padding(.bottom, 4.0)
                .clipShape(rect)
                .overlay(rect.stroke(borderAccentColor, lineWidth: 1.0))
                .accentColor(progressViewAccentColor)
        }
    }
    
    var answerOptionLabel: some View {
        VStack(alignment: .leading, spacing: 12.0) {
            HStack(alignment: .top, spacing: 8.0) {
                
                if !pollClosed {
                    Image(uiImage: answerOption.selected ? Asset.Images.pollCheckboxSelected.image : Asset.Images.pollCheckboxDefault.image)
                }
                
                Text(answerOption.text)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.colors.primaryContent)
                
                if pollClosed && answerOption.winner {
                    Spacer()
                    Image(uiImage: Asset.Images.pollWinnerIcon.image)
                }
            }
            
            HStack {
                ProgressView(value: Double(showResults ? answerOption.count : 0),
                             total: Double(totalAnswerCount))
                    .progressViewStyle(LinearProgressViewStyle())
                    .scaleEffect(x: 1.0, y: 1.2, anchor: .center)
                    .padding(.vertical, 8.0)
                
                if (showResults) {
                    Text(answerOption.count == 1 ? VectorL10n.pollTimelineOneVote : VectorL10n.pollTimelineVotesCount(Int(answerOption.count)))
                        .font(theme.fonts.footnote)
                        .foregroundColor(pollClosed && answerOption.winner ? theme.colors.accent : theme.colors.secondaryContent)
                }
            }
        }
    }
    
    var borderAccentColor: Color {
        guard !pollClosed else {
            return (answerOption.winner ? theme.colors.accent : theme.colors.quinaryContent)
        }
        
        return answerOption.selected ? theme.colors.accent : theme.colors.quinaryContent
    }
    
    var progressViewAccentColor: Color {
        guard !pollClosed else {
            return (answerOption.winner ? theme.colors.accent : theme.colors.quarterlyContent)
        }
        
        return answerOption.selected ? theme.colors.accent : theme.colors.quarterlyContent
    }
}

@available(iOS 14.0, *)
struct PollTimelineAnswerOptionButton_Previews: PreviewProvider {
    static let stateRenderer = MockPollTimelineScreenState.stateRenderer
    static var previews: some View {
        
        Group {
            VStack {
                PollTimelineAnswerOptionButton(answerOption: TimelineAnswerOption(id: "", text: "Test", count: 5, winner: false, selected: false),
                                               pollClosed: false, showResults: true, totalAnswerCount: 100, action: {})
                
                PollTimelineAnswerOptionButton(answerOption: TimelineAnswerOption(id: "", text: "Test", count: 5, winner: false, selected: false),
                                               pollClosed: false, showResults: false, totalAnswerCount: 100, action: {})
                
                PollTimelineAnswerOptionButton(answerOption: TimelineAnswerOption(id: "", text: "Test", count: 8, winner: false, selected: true),
                                               pollClosed: false, showResults: true, totalAnswerCount: 100, action: {})
                
                PollTimelineAnswerOptionButton(answerOption: TimelineAnswerOption(id: "", text: "Test", count: 8, winner: false, selected: true),
                                               pollClosed: false, showResults: false, totalAnswerCount: 100, action: {})
                
                PollTimelineAnswerOptionButton(answerOption: TimelineAnswerOption(id: "",
                                                                                  text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
                                                                                  count: 200, winner: false, selected: false),
                                               pollClosed: false, showResults: true, totalAnswerCount: 1000, action: {})
                
                PollTimelineAnswerOptionButton(answerOption: TimelineAnswerOption(id: "",
                                                                                  text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
                                                                                  count: 200, winner: false, selected: false),
                                               pollClosed: false, showResults: false, totalAnswerCount: 1000, action: {})
            }
            
            VStack {
                PollTimelineAnswerOptionButton(answerOption: TimelineAnswerOption(id: "", text: "Test", count: 5, winner: false, selected: false),
                                               pollClosed: true, showResults: true, totalAnswerCount: 100, action: {})
                
                PollTimelineAnswerOptionButton(answerOption: TimelineAnswerOption(id: "", text: "Test", count: 5, winner: true, selected: false),
                                               pollClosed: true, showResults: true, totalAnswerCount: 100, action: {})
                
                PollTimelineAnswerOptionButton(answerOption: TimelineAnswerOption(id: "", text: "Test", count: 8, winner: false, selected: true),
                                               pollClosed: true, showResults: true, totalAnswerCount: 100, action: {})
                
                PollTimelineAnswerOptionButton(answerOption: TimelineAnswerOption(id: "", text: "Test", count: 8, winner: true, selected: true),
                                               pollClosed: true, showResults: true, totalAnswerCount: 100, action: {})
                
                PollTimelineAnswerOptionButton(answerOption: TimelineAnswerOption(id: "",
                                                                                  text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
                                                                                  count: 200, winner: false, selected: false),
                                               pollClosed: true, showResults: true, totalAnswerCount: 1000, action: {})
                
                PollTimelineAnswerOptionButton(answerOption: TimelineAnswerOption(id: "",
                                                                                  text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
                                                                                  count: 200, winner: true, selected: false),
                                               pollClosed: true, showResults: true, totalAnswerCount: 1000, action: {})
            }
        }
    }
}
