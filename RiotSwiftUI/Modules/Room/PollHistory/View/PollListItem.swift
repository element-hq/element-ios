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
        }
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
        PollListItem(pollData: .init(startDate: .init(), question: "Did you like this poll?"))
    }
}
