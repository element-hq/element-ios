//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct TemplateRoomChatBubbleContentView: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    let bubbleItem: TemplateRoomChatBubbleItem
    
    var body: some View {
        switch bubbleItem.content {
        case .message(let messageContent):
            switch messageContent {
            case .text(let messageContent):
                TemplateRoomChatBubbleMessage(messageContent: messageContent)
            case .image(let imageContent):
                TemplateRoomChatBubbleImage(imageContent: imageContent)
            }
        }
    }
}

// MARK: - Previews

struct TemplateRoomChatBubbleItemView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
    }
}
