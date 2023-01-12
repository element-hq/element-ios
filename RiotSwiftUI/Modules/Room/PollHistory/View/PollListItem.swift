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
    
    private let data: PollListData
    
    init(data: PollListData) {
        self.data = data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(data.startDate.description)
                .foregroundColor(theme.colors.tertiaryContent)
                .font(theme.fonts.caption1)

            HStack(spacing: 8) {
                Image(uiImage: Asset.Images.pollHistory.image)
                    .resizable()
                    .frame(width: 16, height: 16)

                Text(data.question)
                    .foregroundColor(theme.colors.primaryContent)
                    .font(theme.fonts.body)
            }
        }
    }
}

struct PollListItem_Previews: PreviewProvider {
    static var previews: some View {
        PollListItem(data: .init(startDate: .init(), question: "Did you like this poll?"))
    }
}
