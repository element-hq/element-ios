// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct PollListItem: View {
    @Environment(\.theme) private var theme
    
    private let pollData: TimelinePollDetails
    @ScaledMetric private var imageSize = 16
    
    init(pollData: TimelinePollDetails) {
        self.pollData = pollData
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(DateFormatter.pollShortDateFormatter.string(from: pollData.startDate))
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
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if pollData.closed {
                VStack(alignment: .leading, spacing: 12) {
                    let winningOptions = pollData.answerOptions.filter(\.winner)
                    
                    ForEach(winningOptions) {
                        TimelinePollAnswerOptionButton(poll: pollData, answerOption: $0, action: nil)
                    }
                    
                    resultView
                }
            }
        }
    }
    
    private var resultView: some View {
        let text = pollData.totalAnswerCount == 1 ? VectorL10n.pollTimelineTotalFinalResultsOneVote : VectorL10n.pollTimelineTotalFinalResults(Int(pollData.totalAnswerCount))
        
        return Text(text)
            .font(theme.fonts.footnote)
            .foregroundColor(theme.colors.tertiaryContent)
    }
}

extension DateFormatter {
    static let pollShortDateFormatter: DateFormatter = {
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
            let pollData1 = TimelinePollDetails(id: UUID().uuidString,
                                                question: "Do you like polls?",
                                                answerOptions: [.init(id: "id", text: "Yes, of course!", count: 18, winner: true, selected: true)],
                                                closed: true,
                                                startDate: .init(),
                                                totalAnswerCount: 30,
                                                type: .disclosed,
                                                eventType: .started,
                                                maxAllowedSelections: 1,
                                                hasBeenEdited: false,
                                                hasDecryptionError: false)

            let pollData2 = TimelinePollDetails(id: UUID().uuidString,
                                                question: "Do you like polls?",
                                                answerOptions: [.init(id: "id", text: "Yes, of course!", count: 18, winner: true, selected: true)],
                                                closed: false,
                                                startDate: .init(),
                                                totalAnswerCount: 30,
                                                type: .disclosed,
                                                eventType: .started,
                                                maxAllowedSelections: 1,
                                                hasBeenEdited: false,
                                                hasDecryptionError: false)
            
            let pollData3 = TimelinePollDetails(id: UUID().uuidString,
                                                question: "Do you like polls?",
                                                answerOptions: [
                                                    .init(id: "id1", text: "Yes, of course!", count: 15, winner: true, selected: true),
                                                    .init(id: "id2", text: "No, I don't :-(", count: 15, winner: true, selected: true)
                                                ],
                                                closed: true,
                                                startDate: .init(),
                                                totalAnswerCount: 30,
                                                type: .disclosed,
                                                eventType: .started,
                                                maxAllowedSelections: 1,
                                                hasBeenEdited: false,
                                                hasDecryptionError: false)

            ForEach([pollData1, pollData2, pollData3]) { poll in
                PollListItem(pollData: poll)
            }
        }
        .padding()
    }
}
