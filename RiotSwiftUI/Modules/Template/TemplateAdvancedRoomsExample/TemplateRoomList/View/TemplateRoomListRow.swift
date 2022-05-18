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

struct TemplateRoomListRow: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    let avatar: AvatarInputProtocol
    let displayName: String?
    
    var body: some View {
        HStack{
            AvatarImage(avatarData: avatar, size: .medium)
            Text(displayName ?? "")
                .foregroundColor(theme.colors.primaryContent)
                .accessibility(identifier: "roomNameText") 
            Spacer()
        }
        //add to a style
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

struct TemplateRoomListRow_Previews: PreviewProvider {
    static var previews: some View {
        TemplateRoomListRow(avatar: MockAvatarInput.example, displayName: "Alice")
            .addDependency(MockAvatarService.example)
    }
}
