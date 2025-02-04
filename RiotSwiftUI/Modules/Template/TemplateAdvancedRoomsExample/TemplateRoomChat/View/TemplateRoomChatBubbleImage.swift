//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct TemplateRoomChatBubbleImage: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    let imageContent: TemplateRoomChatMessageImageContent
    
    var body: some View {
        EmptyView()
    }
}

// MARK: - Previews

struct TemplateRoomChatBubbleImage_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
        // TODO: New to our SwiftUI Template? Why not implement the image item in the bubble here?
    }
}
