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

import DSBottomSheet
import SwiftUI
import WysiwygComposer

struct Composer: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @State private var focused = false
    @State private var isActionButtonShowing = false
    
    private let horizontalPadding: CGFloat = 12
    private let borderHeight: CGFloat = 40
    private let minTextViewHeight: CGFloat = 20
    private var verticalPadding: CGFloat {
        (borderHeight - minTextViewHeight) / 2
    }
    
    private var topPadding: CGFloat {
        viewModel.viewState.shouldDisplayContext ? 0 : verticalPadding
    }
    
    private var cornerRadius: CGFloat {
        if viewModel.viewState.shouldDisplayContext || wysiwygViewModel.idealHeight > minTextViewHeight {
            return 14
        } else {
            return borderHeight / 2
        }
    }
    
    private var actionButtonAccessibilityIdentifier: String {
        viewModel.viewState.sendMode == .edit ? "editButton" : "sendButton"
    }
    
    private var toggleButtonAcccessibilityIdentifier: String {
        wysiwygViewModel.maximised ? "minimiseButton" : "maximiseButton"
    }
    
    private var toggleButtonImageName: String {
        wysiwygViewModel.maximised ? Asset.Images.minimiseComposer.name : Asset.Images.maximiseComposer.name
    }
    
    private var borderColor: Color {
        focused ? theme.colors.quarterlyContent : theme.colors.quinaryContent
    }
    
    private var formatItems: [FormatItem] {
        FormatType.allCases.map { type in
            FormatItem(
                type: type,
                active: wysiwygViewModel.reversedActions.contains(type.composerAction),
                disabled: wysiwygViewModel.disabledActions.contains(type.composerAction)
            )
        }
    }
    
    // MARK: Public
    
    @ObservedObject var viewModel: ComposerViewModelType.Context
    @ObservedObject var wysiwygViewModel: WysiwygComposerViewModel
    
    let sendMessageAction: (WysiwygComposerContent) -> Void
    let showSendMediaActions: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            if viewModel.viewState.textFormattingEnabled {
                composerContainer
            }
            HStack(alignment: .bottom, spacing: 0) {
                Button {
                    showSendMediaActions()
                } label: {
                    Image(Asset.Images.startComposeModule.name)
                        .resizable()
                        .foregroundColor(theme.colors.tertiaryContent)
                        .frame(width: 14, height: 14)
                }
                .frame(width: 36, height: 36)
                .background(Circle().fill(theme.colors.system))
                .padding(.trailing, 8)
                .accessibilityLabel(VectorL10n.create)
                if viewModel.viewState.textFormattingEnabled {
                    FormattingToolbar(formatItems: formatItems) { type in
                        wysiwygViewModel.apply(type.action)
                    }
                    .frame(height: 44)
                    Spacer()
                } else {
                    composerContainer
                }
                Button {
                    if wysiwygViewModel.plainTextMode {
                        sendMessageAction(wysiwygViewModel.plainTextModeContent)
                    } else {
                        sendMessageAction(wysiwygViewModel.content)
                    }
                    wysiwygViewModel.clearContent()
                } label: {
                    if viewModel.viewState.sendMode == .edit {
                        Image(Asset.Images.saveIcon.name)
                    } else {
                        Image(Asset.Images.sendIcon.name)
                    }
                }
                .frame(width: 36, height: 36)
                .padding(.leading, 8)
                .isHidden(!isActionButtonShowing)
                .accessibilityIdentifier(actionButtonAccessibilityIdentifier)
                .accessibilityLabel(VectorL10n.send)
                .onChange(of: wysiwygViewModel.isContentEmpty) { isEmpty in
                    viewModel.send(viewAction: .contentDidChange(isEmpty: isEmpty))
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isActionButtonShowing = !isEmpty
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
        }
    }

    private var composerContainer: some View {
        let rect = RoundedRectangle(cornerRadius: cornerRadius)
        return VStack(spacing: 12) {
            if viewModel.viewState.shouldDisplayContext {
                HStack {
                    if let imageName = viewModel.viewState.contextImageName {
                        Image(imageName)
                            .foregroundColor(theme.colors.tertiaryContent)
                    }
                    if let contextDescription = viewModel.viewState.contextDescription {
                        Text(contextDescription)
                            .accessibilityIdentifier("contextDescription")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.colors.secondaryContent)
                    }
                    Spacer()
                    Button {
                        viewModel.send(viewAction: .cancel)
                    } label: {
                        Image(Asset.Images.inputCloseIcon.name)
                            .foregroundColor(theme.colors.tertiaryContent)
                    }
                    .accessibilityIdentifier("cancelButton")
                }
                .padding(.top, 8)
                .padding(.horizontal, horizontalPadding)
            }
            HStack(alignment: .top, spacing: 0) {
                WysiwygComposerView(
                    focused: $focused,
                    content: wysiwygViewModel.content,
                    replaceText: wysiwygViewModel.replaceText,
                    select: wysiwygViewModel.select,
                    didUpdateText: wysiwygViewModel.didUpdateText
                )
                .tintColor(theme.colors.accent)
                .placeholder(viewModel.viewState.placeholder, color: theme.colors.tertiaryContent)
                .frame(height: wysiwygViewModel.idealHeight)
                .onAppear {
                    if wysiwygViewModel.isContentEmpty {
                        wysiwygViewModel.setup()
                    }
                }
                if viewModel.viewState.textFormattingEnabled {
                    Button {
                        wysiwygViewModel.maximised.toggle()
                    } label: {
                        Image(toggleButtonImageName)
                            .resizable()
                            .foregroundColor(theme.colors.tertiaryContent)
                            .frame(width: 16, height: 16)
                    }
                    .accessibilityIdentifier(toggleButtonAcccessibilityIdentifier)
                    .padding(.leading, 12)
                    .padding(.trailing, 4)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, topPadding)
            .padding(.bottom, verticalPadding)
        }
        .clipShape(rect)
        .overlay(rect.stroke(borderColor, lineWidth: 1))
        .animation(.easeInOut(duration: 0.1), value: wysiwygViewModel.idealHeight)
        .padding(.horizontal, horizontalPadding)
        .padding(.top, 8)
        .onTapGesture {
            if !focused {
                focused = true
            }
        }
    }
}

// MARK: Previews

struct Composer_Previews: PreviewProvider {
    static let stateRenderer = MockComposerScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
