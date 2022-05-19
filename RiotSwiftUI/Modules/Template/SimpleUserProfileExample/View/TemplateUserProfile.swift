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

struct TemplateUserProfile: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: TemplateUserProfileViewModel.Context
    
    var body: some View {
        VStack {
            TemplateUserProfileHeader(
                avatar: viewModel.viewState.avatar,
                displayName: viewModel.viewState.displayName,
                presence: viewModel.viewState.presence
            )
            Divider()
            HStack{
                Text("Counter: \(viewModel.viewState.count)")
                    .font(theme.fonts.title2)
                    .foregroundColor(theme.colors.secondaryContent)
                Button("-") {
                    viewModel.send(viewAction: .decrementCount)
                }
                Button("+") {
                    viewModel.send(viewAction: .incrementCount)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .background(theme.colors.background)
        .frame(maxHeight: .infinity)
        .navigationTitle(viewModel.viewState.displayName ?? "")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(VectorL10n.done) {
                    viewModel.send(viewAction: .done)
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button(VectorL10n.cancel) {
                    viewModel.send(viewAction: .cancel)
                }
            }
        }
    }
}

// MARK: - Previews

struct TemplateUserProfile_Previews: PreviewProvider {
    static let stateRenderer = MockTemplateUserProfileScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
