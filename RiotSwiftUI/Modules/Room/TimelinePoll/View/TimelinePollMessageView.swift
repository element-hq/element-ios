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

/// A view for showing polls' related messages whenever there aren't enough information to show a full poll in the timeline.
struct TimelinePollMessageView: View {
    @Environment(\.theme) private var theme
    private let imageSize: CGFloat = 16
    
    let message: String
    
    var body: some View {
        HStack {
            Image(uiImage: Asset.Images.pollHistory.image)
                .resizable()
                .frame(width: imageSize, height: imageSize)
            
            Text(message)
                .font(.system(size: 15))
                .foregroundColor(theme.colors.primaryContent)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TimelinePollMessageView_Previews: PreviewProvider {
    static var previews: some View {
        TimelinePollMessageView(message: VectorL10n.pollTimelineReplyEndedPoll)
    }
}
