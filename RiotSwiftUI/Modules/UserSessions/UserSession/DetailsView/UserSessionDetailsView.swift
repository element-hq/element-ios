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

struct UserSessionDetailsView: View {
    
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: UserSessionDetailsViewModel.Context
    
    var body: some View {
        List {
            ForEach(viewModel.viewState.sections) { section in
                SwiftUI.Section {
                    ForEach(section.items) { item in
                        UserSessionDetailsItemView(viewData: item)
                            .listRowInsets(EdgeInsets())
                    }
                } header: {
                    Text(section.header)
                        .foregroundColor(theme.colors.secondaryContent)
                        .font(theme.fonts.footnote)
                        .padding([.leading, .trailing], 20)
                        .padding([.top, .bottom], 8)
                } footer: {
                    if let footer = section.footer {
                        Text(footer)
                            .foregroundColor(theme.colors.secondaryContent)
                            .font(theme.fonts.footnote)
                            .padding([.leading, .trailing], 20)
                            .padding(.top, 8)
                            .padding(.bottom, 32)
                    }
                }
                .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.grouped)
        .navigationBarTitle("Session details", displayMode: .inline)
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
