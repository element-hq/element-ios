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

struct FormPickerItem: View {
    typealias TapCallback = () -> Void
    
    @Environment(\.theme) var theme: ThemeSwiftUI
    
    var title: String
    var selected: Bool
    var onTap: TapCallback?
    
    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack {
                Spacer()
                HStack {
                    Text(title)
                    Spacer()
                    if selected {
                        Image("checkmark")
                            .foregroundColor(theme.colors.accent)
                    }
                }
                .padding(.trailing)
                Spacer()
                Divider()
            }
            .padding(.leading)
        }
        .buttonStyle(FormItemButtonStyle())
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, idealHeight: 44, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct FormPickerItem_Previews: PreviewProvider {
    static let items = ["Item 1", "Item 2", "Item 3"]
    static var selected: String = items[0]
    static var previews: some View {
        VectorForm {
            ForEach(items, id: \.self) { item in
                FormPickerItem(title: item, selected: selected == item)
            }
        }
    }
}
