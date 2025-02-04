//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
