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

struct RadioButton: View {
    
    // MARK: - Properties
    
    var title: String
    var selected: Bool
    let action: () -> Void
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    var body: some View {
        Button(action: action, label: {
            HStack {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .renderingMode(.template)
                    .resizable().frame(width: 20, height: 20)
                    .foregroundColor(selected ? theme.colors.accent : theme.colors.tertiaryContent)
                Text(title)
                    .font(theme.fonts.callout)
                    .foregroundColor(theme.colors.primaryContent)
                Spacer()
            }
            .padding(EdgeInsets(top: 3, leading: 3, bottom: 3, trailing: 3))
            .background(Color.clear)
        })
    }
}

// MARK: - Previews

struct RadioButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            buttonGroup.theme(.light)
            buttonGroup.theme(.dark).preferredColorScheme(.dark)
        }
        .padding()
    }
    
    static var buttonGroup: some View {
        VStack {
            RadioButton(title: "A title", selected: false, action: {})
            RadioButton(title: "A title", selected: true, action: {})
        }
    }
}
