// 
// Copyright 2023 New Vector Ltd
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

struct PollListData {
    let startDate: Date
    let question: String
    let numberOfVotes: UInt
    let winningOption: TimelinePollAnswerOption?
}

struct PollListItem: View {
    @Environment(\.theme) private var theme
    
    private let pollData: PollListData
    @ScaledMetric private var imageSize = 16
    
    init(pollData: PollListData) {
        self.pollData = pollData
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(pollData.formattedDate)
                .foregroundColor(theme.colors.tertiaryContent)
                .font(theme.fonts.caption1)
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(uiImage: Asset.Images.pollHistory.image)
                    .resizable()
                    .frame(width: imageSize, height: imageSize)
                
                Text(pollData.question)
                    .foregroundColor(theme.colors.primaryContent)
                    .font(theme.fonts.body)
                    .lineLimit(2)
                    .accessibilityLabel("PollListItem.title")
            }
            
            if pollData.winningOption != nil {
                VStack(alignment: .leading, spacing: 12) {
                    optionView(winningOption: pollData.winningOption!)
                    resultView
                }
            }
        }
    }
    
    private var clipShape: some Shape {
        RoundedRectangle(cornerRadius: 4.0)
    }

    private func optionView(winningOption: TimelinePollAnswerOption) -> some View {
        VStack(alignment: .leading, spacing: 12.0) {
            HStack(alignment: .top, spacing: 8.0) {
                Text(pollData.winningOption!.text)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.colors.primaryContent)
                    .accessibilityIdentifier("PollListData.winningOption")
                
                Spacer()
                
                votesText(winningOption: winningOption)
            }
            
            ProgressView(value: Double(winningOption.count),
                         total: Double(pollData.numberOfVotes))
                .progressViewStyle(LinearProgressViewStyle())
                .scaleEffect(x: 1.0, y: 1.2, anchor: .center)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8.0)
        .padding(.top, 12.0)
        .padding(.bottom, 12.0)
        .clipShape(clipShape)
        .overlay(clipShape.stroke(theme.colors.accent, lineWidth: 1.0))
        .accentColor(theme.colors.accent)
    }
    
    private func votesText(winningOption: TimelinePollAnswerOption) -> some View {
        Label {
            Text(winningOption.count == 1 ? VectorL10n.pollTimelineOneVote : VectorL10n.pollTimelineVotesCount(Int(winningOption.count)))
                .font(theme.fonts.footnote)
                .foregroundColor(theme.colors.accent)
        } icon: {
            Image(uiImage: Asset.Images.pollWinnerIcon.image)
        }
    }
    
    private var resultView: some View {
        let text = pollData.numberOfVotes == 1 ? VectorL10n.pollTimelineTotalFinalResultsOneVote : VectorL10n.pollTimelineTotalFinalResults(Int(pollData.numberOfVotes))
        
        return Text(text)
            .font(theme.fonts.footnote)
            .foregroundColor(theme.colors.tertiaryContent)
    }
}

private extension PollListData {
    var formattedDate: String {
        DateFormatter.shortDateFormatter.string(from: startDate)
    }
}

private extension DateFormatter {
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .short
        formatter.timeZone = .init(identifier: "UTC")
        return formatter
    }()
}

// MARK: - Previews

struct PollListItem_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let pollData1 = PollListData(
                startDate: .init(),
                question: "Do you like polls?",
                numberOfVotes: 30,
                winningOption: .init(id: "id", text: "Yes, of course!", count: 18, winner: true, selected: true)
            )
            
            PollListItem(pollData: pollData1)
            
            let pollData2 = PollListData(
                startDate: .init(),
                question: "Do you like polls?",
                numberOfVotes: 30,
                winningOption: nil)
            
            PollListItem(pollData: pollData2)
        }
        .padding()
    }
}
