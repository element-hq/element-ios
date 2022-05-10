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

struct TemplateRoomChatBubbleView: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    let bubble: TemplateRoomChatBubble
    
    var body: some View {
        HStack(alignment: .top){
            AvatarImage(avatarData: bubble.sender.avatarData, size: .xSmall)
                .accessibility(identifier: "bubbleImage")
            VStack(alignment: .leading){
                Text(bubble.sender.displayName ?? "")
                    .foregroundColor(theme.userColor(for: bubble.sender.id))
                    .font(theme.fonts.bodySB)
                ForEach(bubble.items) { item in
                    TemplateRoomChatBubbleContentView(bubbleItem: item)
                }
            }
            Spacer()
        }
        //add to a style
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
            .addDependency(MockAvatarService.example)
    }
}
