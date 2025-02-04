//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct ComposerLinkAction: View {
    enum Field {
        case text
        case link
    }
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    @ObservedObject private var viewModel: ComposerLinkActionViewModel.Context
    
    @State private var selectedField: Field?
    
    private var isTextFocused: Bool {
        selectedField == .text
    }
    
    private var isLinkFocused: Bool {
        selectedField == .link
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 24) {
                    if viewModel.viewState.shouldDisplayTextField {
                        VStack(alignment: .leading, spacing: 8.0) {
                            Text(VectorL10n.wysiwygComposerLinkActionText)
                                .font(theme.fonts.subheadline)
                                .foregroundColor(theme.colors.secondaryContent)
                            TextField(
                                "",
                                text: $viewModel.text,
                                onEditingChanged: { edit in
                                    selectedField = edit ? .text : nil
                                }
                            )
                            .textFieldStyle(BorderedInputFieldStyle(isEditing: isTextFocused))
                            .autocapitalization(.none)
                            .accessibilityIdentifier("textTextField")
                            .accessibilityLabel(VectorL10n.wysiwygComposerLinkActionText)
                        }
                    }
                    VStack(alignment: .leading, spacing: 8.0) {
                        Text(VectorL10n.wysiwygComposerLinkActionLink)
                            .font(theme.fonts.subheadline)
                            .foregroundColor(theme.colors.secondaryContent)
                        TextField(
                            "",
                            text: $viewModel.linkUrl,
                            onEditingChanged: { edit in
                                selectedField = edit ? .link : nil
                            }
                        )
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .textFieldStyle(BorderedInputFieldStyle(isEditing: isLinkFocused))
                        .accessibilityIdentifier("linkTextField")
                        .accessibilityLabel(VectorL10n.wysiwygComposerLinkActionLink)
                    }
                }
                Spacer()
                VStack(spacing: 16) {
                    Button(VectorL10n.save) {
                        viewModel.send(viewAction: .save)
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .disabled(viewModel.viewState.isSaveButtonDisabled)
                    .animation(.easeInOut(duration: 0.15), value: viewModel.viewState.isSaveButtonDisabled)
                    if viewModel.viewState.shouldDisplayRemoveButton {
                        Button(VectorL10n.remove) {
                            viewModel.send(viewAction: .remove)
                        }
                        .buttonStyle(PrimaryActionButtonStyle(customColor: theme.colors.alert))
                    }
                    Button(VectorL10n.cancel) {
                        viewModel.send(viewAction: .cancel)
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                }
            }
            .padding(.top, 40.0)
            .padding(.bottom, 12.0)
            .padding(.horizontal, 16.0)
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
            .accentColor(theme.colors.accent)
            .navigationViewStyle(StackNavigationViewStyle())
        }
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
