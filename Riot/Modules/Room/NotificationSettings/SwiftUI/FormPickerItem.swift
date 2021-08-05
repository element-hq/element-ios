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

@available(iOS 13.0, *)
struct FormPickerItem: View {
    
    typealias ClickCallback = () -> Void
    
    @Environment(\.theme) var theme: Theme
    
    var title: String
    var selected: Bool
    var onClick: ClickCallback?
    
    var body: some View {
        HStack {
            Text(title)
                .font(Font(theme.fonts.body))
                .foregroundColor(Color(theme.textPrimaryColor))
            Spacer()
            if selected {
                Image("checkmark")
                    .foregroundColor(Color(theme.tintColor))
            }
        }
        .listRowBackground(Color(theme.backgroundColor))
        .contentShape(Rectangle())
        .onTapGesture {
            onClick?()
        }
    }
}

@available(iOS 13.0, *)
struct FormPickerCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            FormPickerItem(title: "Item 1", selected: true, onClick: nil)
            FormPickerItem(title: "Item 2", selected: false, onClick: nil)
            FormPickerItem(title: "Item 3", selected: false, onClick: nil)
        }.listStyle(GroupedListStyle())
        
    }
}
