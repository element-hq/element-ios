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

struct UserSessionDetails: View {
    private enum LayoutConstants {
        static let listItemHorizontalPadding: CGFloat = 20
        static let sectionVerticalPadding: CGFloat = 8
    }
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @ObservedObject var viewModel: UserSessionDetailsViewModel.Context
    
    var body: some View {
        List {
            ForEach(viewModel.viewState.sections) { section in
                SwiftUI.Section {
                    ForEach(section.items) { item in
                        UserSessionDetailsItem(viewData: item, horizontalPadding: LayoutConstants.listItemHorizontalPadding)
                            .listRowInsets(EdgeInsets())
                    }
                } header: {
                    Text(section.header)
                        .foregroundColor(theme.colors.secondaryContent)
                        .font(theme.fonts.footnote)
                        .padding([.leading, .trailing], LayoutConstants.listItemHorizontalPadding)
                        .padding(.top, 32)
                        .padding(.bottom, LayoutConstants.sectionVerticalPadding)
                } footer: {
                    if let footer = section.footer {
                        Text(footer)
                            .foregroundColor(theme.colors.secondaryContent)
                            .font(theme.fonts.footnote)
                            .padding([.leading, .trailing], LayoutConstants.listItemHorizontalPadding)
                            .padding(.top, LayoutConstants.sectionVerticalPadding)
                    }
                }
                .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.grouped)
        .navigationBarTitle(VectorL10n.userSessionDetailsTitle)
    }
}

// MARK: - Previews

struct UserSessionDetails_Previews: PreviewProvider {
    static let stateRenderer = MockUserSessionDetailsScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true).theme(.light).preferredColorScheme(.light)
        stateRenderer.screenGroup(addNavigation: true).theme(.dark).preferredColorScheme(.dark)
    }
}
