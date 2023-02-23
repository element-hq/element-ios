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

struct TimelinePollAnswerOptionButton: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    let poll: TimelinePollDetails
    let answerOption: TimelinePollAnswerOption
    let action: () -> Void
    
    // MARK: Public
    
    var body: some View {
        Button(action: action) {
            let rect = RoundedRectangle(cornerRadius: 4.0)
            answerOptionLabel
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8.0)
                .padding(.top, 12.0)
                .padding(.bottom, 12.0)
                .clipShape(rect)
                .overlay(rect.stroke(borderAccentColor, lineWidth: 1.0))
                .accentColor(progressViewAccentColor)
        }
        .accessibilityIdentifier("PollAnswerOption\(optionIndex)")
    }
    
    var answerOptionLabel: some View {
        VStack(alignment: .leading, spacing: 12.0) {
            HStack(alignment: .top, spacing: 8.0) {
                if !poll.closed {
                    Image(uiImage: answerOption.selected ? Asset.Images.pollCheckboxSelected.image : Asset.Images.pollCheckboxDefault.image)
                }
                
                Text(answerOption.text)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.colors.primaryContent)
                    .accessibilityIdentifier("PollAnswerOption\(optionIndex)Label")
                
                if poll.closed, answerOption.winner {
                    Spacer()
                    Image(uiImage: Asset.Images.pollWinnerIcon.image)
                }
            }
            
            if poll.type == .disclosed || poll.closed {
                HStack {
                    ProgressView(value: Double(poll.shouldDiscloseResults ? answerOption.count : 0),
                                 total: Double(poll.totalAnswerCount))
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(x: 1.0, y: 1.2, anchor: .center)
                        .accessibilityIdentifier("PollAnswerOption\(optionIndex)Progress")
                    
                    if poll.shouldDiscloseResults {
                        Text(answerOption.count == 1 ? VectorL10n.pollTimelineOneVote : VectorL10n.pollTimelineVotesCount(Int(answerOption.count)))
                            .font(theme.fonts.footnote)
                            .foregroundColor(poll.closed && answerOption.winner ? theme.colors.accent : theme.colors.secondaryContent)
                            .accessibilityIdentifier("PollAnswerOption\(optionIndex)Count")
                    }
                }
            }
        }
    }
    
    var borderAccentColor: Color {
        guard !poll.closed else {
            return (answerOption.winner ? theme.colors.accent : theme.colors.quinaryContent)
        }
        
        return answerOption.selected ? theme.colors.accent : theme.colors.quinaryContent
    }
    
    var progressViewAccentColor: Color {
        guard !poll.closed else {
            return (answerOption.winner ? theme.colors.accent : theme.colors.quarterlyContent)
        }
        
        return answerOption.selected ? theme.colors.accent : theme.colors.quarterlyContent
    }
    
    var optionIndex: Int {
        poll.answerOptions.firstIndex { $0.id == answerOption.id } ?? Int.max
    }
}

struct TimelinePollAnswerOptionButton_Previews: PreviewProvider {
    static let stateRenderer = MockTimelinePollScreenState.stateRenderer
    
    static var previews: some View {
        Group {
            let pollTypes: [TimelinePollType] = [.disclosed, .undisclosed]
            
            ForEach(pollTypes, id: \.self) { type in
                VStack {
                    TimelinePollAnswerOptionButton(poll: buildPoll(closed: false, type: type),
                                                   answerOption: buildAnswerOption(selected: false),
                                                   action: { })
                    
                    TimelinePollAnswerOptionButton(poll: buildPoll(closed: false, type: type),
                                                   answerOption: buildAnswerOption(selected: true),
                                                   action: { })
                    
                    TimelinePollAnswerOptionButton(poll: buildPoll(closed: true, type: type),
                                                   answerOption: buildAnswerOption(selected: false, winner: false),
                                                   action: { })

                    TimelinePollAnswerOptionButton(poll: buildPoll(closed: true, type: type),
                                                   answerOption: buildAnswerOption(selected: false, winner: true),
                                                   action: { })

                    TimelinePollAnswerOptionButton(poll: buildPoll(closed: true, type: type),
                                                   answerOption: buildAnswerOption(selected: true, winner: false),
                                                   action: { })

                    TimelinePollAnswerOptionButton(poll: buildPoll(closed: true, type: type),
                                                   answerOption: buildAnswerOption(selected: true, winner: true),
                                                   action: { })

                    let longText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."

                    TimelinePollAnswerOptionButton(poll: buildPoll(closed: true, type: type),
                                                   answerOption: buildAnswerOption(text: longText, selected: true, winner: true),
                                                   action: { })
                }
            }
        }
    }
    
    static func buildPoll(closed: Bool, type: TimelinePollType) -> TimelinePollDetails {
        TimelinePollDetails(question: "",
                            answerOptions: [],
                            closed: closed,
                            totalAnswerCount: 100,
                            type: type,
                            maxAllowedSelections: 1,
                            hasBeenEdited: false)
    }
    
    static func buildAnswerOption(text: String = "Test", selected: Bool, winner: Bool = false) -> TimelinePollAnswerOption {
        TimelinePollAnswerOption(id: "1", text: text, count: 5, winner: winner, selected: selected)
    }
}
