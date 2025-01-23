//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct FormSectionFooter: View {
    @Environment(\.theme) var theme: ThemeSwiftUI
    var text: String
    
    var body: some View {
        Text(text)
            .foregroundColor(theme.colors.secondaryContent)
            .padding(.top)
            .padding(.leading)
            .padding(.trailing)
            .font(theme.fonts.subheadline)
    }
}

struct FormSectionFooter_Previews: PreviewProvider {
    static var previews: some View {
        VectorForm {
            SwiftUI.Section(footer: FormSectionFooter(text: "Please note that mentions & keyword notifications are not available in encrypted rooms on mobile.")) {
                FormPickerItem(title: "Item 1", selected: false)
                FormPickerItem(title: "Item 2", selected: false)
                FormPickerItem(title: "Item 3", selected: false)
            }
        }
    }
}
