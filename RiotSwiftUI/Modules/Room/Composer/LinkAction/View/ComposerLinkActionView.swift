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

struct ComposerLinkActionView: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    @ObservedObject private var viewModel: ComposerLinkActionViewModel.Context
    
    var body: some View {
        NavigationView {
            VStack {}
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(VectorL10n.cancel, action: {
                            viewModel.send(viewAction: .cancel)
                        })
                    }
                    ToolbarItem(placement: .principal) {
                        Text(viewModel.viewState.title)
                            .font(.headline)
                            .foregroundColor(theme.colors.primaryContent)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .introspectNavigationController { navigationController in
                    ThemeService.shared().theme.applyStyle(onNavigationBar: navigationController.navigationBar)
                }
        }
        .accentColor(theme.colors.accent)
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    init(viewModel: ComposerLinkActionViewModel.Context) {
        self.viewModel = viewModel
    }
}

struct ComposerLinkActionView_Previews: PreviewProvider {
    static let stateRenderer = MockComposerLinkActionScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
