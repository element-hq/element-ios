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
    @State private var isActionButtonEnabled = false
    
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
            let rect = RoundedRectangle(cornerRadius: cornerRadius)
            // TODO: Fix maximise animation bugs before re-enabling
            //            ZStack(alignment: .topTrailing) {
            VStack(spacing: 12) {
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
                WysiwygComposerView(
                    focused: $focused,
                    content: wysiwygViewModel.content,
                    replaceText: wysiwygViewModel.replaceText,
                    select: wysiwygViewModel.select,
                    didUpdateText: wysiwygViewModel.didUpdateText
                )
                .tintColor(theme.colors.accent)
                .frame(height: wysiwygViewModel.idealHeight)
                .padding(.horizontal, horizontalPadding)
                .onAppear {
                    wysiwygViewModel.setup()
                }
                //                Button {
                //                    withAnimation(.easeInOut(duration: 0.25)) {
                //                        viewModel.maximised.toggle()
                //                    }
                //                } label: {
                //                    Image(viewModel.maximised ? Asset.Images.minimiseComposer.name : Asset.Images.maximiseComposer.name)
                //                        .foregroundColor(theme.colors.tertiaryContent)
                //                }
                //                .padding(.top, 4)
                //                .padding(.trailing, 12)
                //            }
                .padding(.top, topPadding)
                .padding(.bottom, verticalPadding)
            }
            .clipShape(rect)
            .overlay(rect.stroke(borderColor, lineWidth: 1))
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 8)
            .onTapGesture {
                if !focused {
                    focused = true
                }
            }
            HStack(spacing: 0) {
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
                FormattingToolbar(formatItems: formatItems) { type in
                    wysiwygViewModel.apply(type.action)
                }
                .frame(height: 44)
                Spacer()
                //                ZStack {
                // TODO: Add support for voice messages
                //                    Button {
                //
                //                    } label: {
                //                        Image(Asset.Images.voiceMessageRecordButtonDefault.name)
                //                            .foregroundColor(theme.colors.tertiaryContent)
                //                    }
                //                        .isHidden(showSendButton)
                //                    .isHidden(true)
                Button {
                    sendMessageAction(wysiwygViewModel.content)
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
                .disabled(!isActionButtonEnabled)
                .opacity(isActionButtonEnabled ? 1 : 0.3)
                .animation(.easeInOut(duration: 0.15), value: isActionButtonEnabled)
                .accessibilityIdentifier(actionButtonAccessibilityIdentifier)
                .accessibilityLabel(VectorL10n.send)
                .onChange(of: wysiwygViewModel.isContentEmpty) { empty in
                    isActionButtonEnabled = !empty
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
            .animation(.none)
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
