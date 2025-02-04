//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
