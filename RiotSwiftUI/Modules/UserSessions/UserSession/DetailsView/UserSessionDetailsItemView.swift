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

struct UserSessionDetailsItemView: View {
    
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    let viewData: UserSessionDetailsSectionItemViewData
    
    var body: some View {
        HStack() {
            Text(viewData.title)
                .font(theme.fonts.subheadline)
                .foregroundColor(theme.colors.secondaryContent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(maxHeight: .infinity, alignment: .top)
            Text(viewData.value)
                .font(theme.fonts.subheadline)
                .foregroundColor(theme.colors.primaryContent)
                .multilineTextAlignment(.trailing)
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = viewData.value
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
        .padding([.leading, .trailing], 20)
        .padding([.top, .bottom], 12)
    }
}

// MARK: - Previews

struct UserSessionDetailsItemView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            List {
                UserSessionDetailsItemView(viewData: UserSessionDetailsSectionItemViewData(title: "Session name", value: "123"))
                    .theme(.light)
                    .preferredColorScheme(.light)
                    .listRowInsets(EdgeInsets())
            }
            .listStyle(.grouped)
            List {
                UserSessionDetailsItemView(viewData: UserSessionDetailsSectionItemViewData(title: "Session name", value: "123"))
                    .theme(.dark)
                    .preferredColorScheme(.dark)
                    .listRowInsets(EdgeInsets())
            }
            .listStyle(.grouped)
        }
    }
}
