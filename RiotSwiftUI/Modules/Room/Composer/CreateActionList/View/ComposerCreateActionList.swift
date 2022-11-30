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

struct ComposerCreateActionList: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI

    private var textFormattingIcon: String {
        viewModel.textFormattingEnabled
        ? Asset.Images.actionFormattingEnabled.name
        : Asset.Images.actionFormattingDisabled.name
    }
    
    // MARK: Public
    
    @ObservedObject var viewModel: ComposerCreateActionListViewModel.Context
    
    private var internalView: some View {
        VStack(alignment: .leading) {
            ForEach(viewModel.viewState.actions) { action in
                HStack(spacing: 16) {
                    Image(action.icon)
                        .renderingMode(.template)
                        .foregroundColor(theme.colors.accent)
                    Text(action.title)
                        .foregroundColor(theme.colors.primaryContent)
                        .font(theme.fonts.body)
                        .accessibilityIdentifier(action.accessibilityIdentifier)
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.send(viewAction: .selectAction(action))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            if viewModel.viewState.wysiwygEnabled {
                SeparatorLine()
                HStack(spacing: 16) {
                    Image(textFormattingIcon)
                        .renderingMode(.template)
                        .foregroundColor(theme.colors.accent)
                    Text(VectorL10n.wysiwygComposerStartActionTextFormatting)
                        .foregroundColor(theme.colors.primaryContent)
                        .font(theme.fonts.body)
                        .accessibilityIdentifier("textFormatting")
                    Spacer()
                    Toggle("", isOn: $viewModel.textFormattingEnabled)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: theme.colors.accent))
                        .onChange(of: viewModel.textFormattingEnabled) { isOn in
                            viewModel.send(viewAction: .toggleTextFormatting(isOn))
                        }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.textFormattingEnabled.toggle()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            }
        }
    }

    var body: some View {
        if viewModel.viewState.isScrollingEnabled {
            ScrollView {
                internalView
            }
            .padding(.top, 23)
            .background(theme.colors.background.ignoresSafeArea())
        } else {
            VStack {
                internalView
                Spacer()
            }
            .padding(.top, 23)
            .background(theme.colors.background.ignoresSafeArea())
        }
    }
}

// MARK: - Previews

struct ComposerCreateActionList_Previews: PreviewProvider {
    static let stateRenderer = MockComposerCreateActionListScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
