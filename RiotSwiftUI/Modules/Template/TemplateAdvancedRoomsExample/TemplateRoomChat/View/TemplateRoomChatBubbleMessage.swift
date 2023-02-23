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
