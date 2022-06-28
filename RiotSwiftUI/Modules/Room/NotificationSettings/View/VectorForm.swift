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
