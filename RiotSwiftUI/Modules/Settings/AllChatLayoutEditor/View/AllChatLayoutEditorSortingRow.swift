// 
// Copyright 2022 New Vector Ltd
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

struct AllChatLayoutEditorSortingRow: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    private var tintColor: Color {
        option.selected ? theme.colors.background : theme.colors.secondaryContent
    }
    
    private var backColor: Color {
        option.selected ? theme.colors.accent : theme.colors.background
    }
    
    // MARK: Public
    
    var option: AllChatLayoutEditorSortingOption
    
    @ViewBuilder
    var body: some View {
        HStack {
            RadioButton(title: option.name, selected: option.selected, action: {})
                .allowsHitTesting(false)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(theme.colors.background)
        .cornerRadius(16)
    }
}

struct AllChatLayoutEditorSortingRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            preview
            .background(Color.gray)
            preview
            .theme(.dark)
            .preferredColorScheme(.dark)
        }
        .padding()
    }
    
    private static var preview: some View {
        VStack(spacing: 16) {
            AllChatLayoutEditorSortingRow(option: AllChatLayoutEditorSortingOption(type: .activity, name: VectorL10n.allChatsEditLayoutActivityOrder, selected: false))
            AllChatLayoutEditorSortingRow(option: AllChatLayoutEditorSortingOption(type: .alphabetical, name: VectorL10n.allChatsEditLayoutAlphabeticalOrder, selected: false))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
