//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
