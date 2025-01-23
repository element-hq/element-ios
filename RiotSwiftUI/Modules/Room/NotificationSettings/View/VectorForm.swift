//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct VectorForm<Content: View>: View {
    @Environment(\.theme) var theme: ThemeSwiftUI
    var content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0, content: content)
        }
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .top
        )
        .background(theme.colors.system)
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct VectorForm_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VectorForm {
                SwiftUI.Section(header: FormSectionHeader(text: "Section Header")) {
                    FormPickerItem(title: "Item 1", selected: true)
                    FormPickerItem(title: "Item 2", selected: false)
                    FormPickerItem(title: "Item 3", selected: false)
                }
            }
            VectorForm {
                FormPickerItem(title: "Item 1", selected: true)
            }
            .theme(ThemeIdentifier.dark)
        }
    }
}
