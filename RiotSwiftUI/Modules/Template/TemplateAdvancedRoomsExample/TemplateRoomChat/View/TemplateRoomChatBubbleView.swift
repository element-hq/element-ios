//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct TemplateRoomChatBubbleView: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    let bubble: TemplateRoomChatBubble
    
    var body: some View {
        HStack(alignment: .top) {
            AvatarImage(avatarData: bubble.sender.avatarData, size: .xSmall)
                .accessibility(identifier: "bubbleImage")
            VStack(alignment: .leading) {
                Text(bubble.sender.displayName ?? "")
                    .foregroundColor(theme.userColor(for: bubble.sender.id))
                    .font(theme.fonts.bodySB)
                ForEach(bubble.items) { item in
                    TemplateRoomChatBubbleContentView(bubbleItem: item)
                }
            }
            Spacer()
        }
        // add to a style
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

struct TemplateRoomChatBubbleView_Previews: PreviewProvider {
    static let bubble = TemplateRoomChatBubble(
        id: "111",
        sender: MockTemplateRoomChatService.mockMessages[0].sender,
        items: [
            TemplateRoomChatBubbleItem(
                id: "222",
                timestamp: Date(),
                content: .message(.text(TemplateRoomChatMessageTextContent(body: "Hello")))
            )
        ]
    )
    static var previews: some View {
        TemplateRoomChatBubbleView(bubble: bubble)
            .environmentObject(AvatarViewModel.withMockedServices())
    }
}
