//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct TemplateRoomChatBubbleMessage: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    let messageContent: TemplateRoomChatMessageTextContent
    
    var body: some View {
        Text(messageContent.body)
            .accessibility(identifier: "bubbleTextContent")
            .foregroundColor(theme.colors.primaryContent)
            .font(theme.fonts.body)
    }
}

// MARK: - Previews

struct TemplateRoomChatBubbleMessage_Previews: PreviewProvider {
    static let message = TemplateRoomChatMessageTextContent(body: "Hello")
    static var previews: some View {
        TemplateRoomChatBubbleMessage(messageContent: message)
    }
}
