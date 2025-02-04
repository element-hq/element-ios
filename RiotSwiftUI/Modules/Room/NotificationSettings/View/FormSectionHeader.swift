//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct FormSectionHeader: View {
    @Environment(\.theme) var theme: ThemeSwiftUI
    var text: String
    
    var body: some View {
        Text(text)
            .foregroundColor(theme.colors.secondaryContent)
            .padding(.top, 32)
            .padding(.leading)
            .padding(.bottom, 8)
            .font(theme.fonts.footnote)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FormSectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        VectorForm {
            SwiftUI.Section(header: FormSectionHeader(text: "Section Header")) {
                FormPickerItem(title: "Item 1", selected: false)
                FormPickerItem(title: "Item 2", selected: false)
                FormPickerItem(title: "Item 3", selected: false)
            }
        }
    }
}
