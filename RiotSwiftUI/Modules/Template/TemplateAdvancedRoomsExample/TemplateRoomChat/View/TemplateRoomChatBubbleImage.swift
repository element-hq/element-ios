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

@available(iOS 15.0, *)
struct TemplateRoomChatBubbleImage: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI

    // MARK: Public
    
    let imageContent: TemplateRoomChatMessageImageContent
    @State var showImageViewer: Bool = false
    var body: some View {
        AsyncImage(url: imageContent.url) { image in
            image.resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: CGFloat(258), height: CGFloat(150))
                .cornerRadius(8)
        } placeholder: {
            Color.green
        }
    }
}

// MARK: - Previews

@available(iOS 15.0, *)
struct TemplateRoomChatBubbleImage_Previews: PreviewProvider {
    static let exampleUrl = URL(string: "https://docs-assets.developer.apple.com/published/9c4143a9a48a080f153278c9732c03e7/17400/SwiftUI-Image-waterWheel-resize~dark@2x.png")!
    static var previews: some View {
        TemplateRoomChatBubbleImage(imageContent: TemplateRoomChatMessageImageContent(url:exampleUrl))
    }
}
