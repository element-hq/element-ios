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
import WysiwygComposer

struct FormattingToolbar: View {
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    var formatItems: [FormatItem]
    var formatAction: (FormatType) -> ()
    
    var body: some View {
        HStack {
           ForEach(formatItems) { item in
               Button {
                   print("action")
                   formatAction(item.type)
               } label: {
                   Image(item.icon)
                       .renderingMode(.template)
                       .foregroundColor(item.active ? theme.colors.accent : theme.colors.tertiaryContent)
               }
               .disabled(item.disabled)
               .background(item.active ? theme.colors.accent.opacity(0.1) : theme.colors.background)
                   .cornerRadius(8)
               .accessibilityIdentifier(item.accessibilityIdentifier)
           }

       }
    }
}

struct FormattingToolbar_Previews: PreviewProvider {
    static var previews: some View {
        FormattingToolbar(formatItems: [
            FormatItem(type: .bold, active: true, disabled: false),
            FormatItem(type: .italic, active: false, disabled: false),
            FormatItem(type: .strikethrough, active: true, disabled: false),
            FormatItem(type: .underline, active: false, disabled: true)
        ], formatAction: { _ in })
    }
}
