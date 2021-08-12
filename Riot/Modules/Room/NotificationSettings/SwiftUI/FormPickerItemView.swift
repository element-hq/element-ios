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

@available(iOS 14.0, *)
struct FormPickerItemView: View {
    
    typealias ClickCallback = () -> Void
    
    @Environment(\.theme) var theme: Theme
    
    var title: String
    var selected: Bool
    var onClick: ClickCallback?
    
    var body: some View {
        Button {
            onClick?()
        } label: {
            VStack {
                Spacer()
                HStack {
                    Text(title)
                    Spacer()
                    if selected {
                        Image("checkmark")
                            .foregroundColor(Color(theme.tintColor))
                    }
                }
                .padding(.trailing)
                Spacer()
                Divider()
            }
            .padding(.leading)
        }
        .buttonStyle(VectorFormItemButtonStyle())
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, idealHeight: 44, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}

@available(iOS 14.0, *)
struct FormPickerCell_Previews: PreviewProvider {
    static let items = ["Item 1", "Item 2", "Item 3"]
    static var selected: String = items[0]
    static var previews: some View {
        VectorFormView {
            ForEach(items, id: \.self) { item in
                FormPickerItemView(title: item, selected: selected == item)
            }
        }
    }
}
