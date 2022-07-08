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

struct AllChatsLayoutEditorFilterItem: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    private var tintColor: Color {
        filter.selected ? theme.colors.background : theme.colors.secondaryContent
    }
    
    private var backColor: Color {
        filter.selected ? theme.colors.accent : theme.colors.background
    }
    
    private var accessoryImageName: String {
        filter.selected ? "checkmark" : "plus"
    }
    
    // MARK: Public
    
    var filter: AllChatsLayoutEditorFilter
    
    @ViewBuilder
    var body: some View {
        HStack(spacing: 10) {
            Image(uiImage: filter.image)
                .renderingMode(.template)
                .resizable()
                .foregroundColor(tintColor)
                .frame(width: 20, height: 20)
            Text(filter.name)
                .foregroundColor(tintColor)
                .font(theme.fonts.callout)
            Image(systemName: accessoryImageName)
                .renderingMode(.template)
                .font(theme.fonts.footnote)
                .foregroundColor(tintColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(backColor)
        .cornerRadius(16)
    }
}

struct AllChatLayoutEditorFilterItem_Previews: PreviewProvider {
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
            HStack(spacing: 16) {
                AllChatsLayoutEditorFilterItem(filter: AllChatsLayoutEditorFilter(type: .favourites, name: VectorL10n.titleFavourites, image: Asset.Images.tabFavourites.image, selected: false))
                AllChatsLayoutEditorFilterItem(filter: AllChatsLayoutEditorFilter(type: .unreads, name: VectorL10n.allChatsEditLayoutUnreads, image: Asset.Images.allChatUnreads.image, selected: false))
            }
            
            HStack(spacing: 16) {
                AllChatsLayoutEditorFilterItem(filter: AllChatsLayoutEditorFilter(type: .favourites, name: VectorL10n.titleFavourites, image: Asset.Images.tabFavourites.image, selected: true))
                AllChatsLayoutEditorFilterItem(filter: AllChatsLayoutEditorFilter(type: .unreads, name: VectorL10n.allChatsEditLayoutUnreads, image: Asset.Images.allChatUnreads.image, selected: true))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
