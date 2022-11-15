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

struct UserSessionDetailsItem: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    let viewData: UserSessionDetailsSectionItemViewData
    let horizontalPadding: CGFloat
    
    init(viewData: UserSessionDetailsSectionItemViewData, horizontalPadding: CGFloat = 20) {
        self.viewData = viewData
        self.horizontalPadding = horizontalPadding
    }
    
    var body: some View {
        HStack {
            Text(viewData.title)
                .font(theme.fonts.subheadline)
                .foregroundColor(theme.colors.secondaryContent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(maxHeight: .infinity, alignment: .top)
                .accessibility(identifier: "UserSessionDetailsItem.title")
            Text(viewData.value)
                .font(theme.fonts.subheadline)
                .foregroundColor(theme.colors.primaryContent)
                .multilineTextAlignment(.trailing)
                .accessibility(identifier: "UserSessionDetailsItem.value")
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = viewData.value
            } label: {
                Label(VectorL10n.copyButtonName, systemImage: "doc.on.doc")
            }
        }
        .padding([.leading, .trailing], horizontalPadding)
        .padding([.top, .bottom], 12)
    }
}

// MARK: - Previews

struct UserSessionDetailsItem_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            List {
                UserSessionDetailsItem(viewData: UserSessionDetailsSectionItemViewData(title: "Session name",
                                                                                       value: "Element Web: Firefox on macOS"))
                    .listRowInsets(EdgeInsets())
                UserSessionDetailsItem(viewData: UserSessionDetailsSectionItemViewData(title: "Session ID",
                                                                                       value: "76c95352559d-react-7c57680b93db-js-b64dbdce74b0"))
                    .listRowInsets(EdgeInsets())
            }
            .preferredColorScheme(.light)
            
            .listStyle(.grouped)
            List {
                UserSessionDetailsItem(viewData: UserSessionDetailsSectionItemViewData(title: "Session name",
                                                                                       value: "Element Web: Firefox on macOS"))
                    .listRowInsets(EdgeInsets())
                UserSessionDetailsItem(viewData: UserSessionDetailsSectionItemViewData(title: "Session ID",
                                                                                       value: "76c95352559d-react-7c57680b93db-js-b64dbdce74b0"))
                    .listRowInsets(EdgeInsets())
            }
            .preferredColorScheme(.dark)
            .theme(.dark)
            .listStyle(.grouped)
        }
    }
}
