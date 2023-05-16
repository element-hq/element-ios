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
import WysiwygComposer

struct Composer: View {
    // MARK: - Properties
    
    // MARK: Private
    @ObservedObject private var viewModel: ComposerViewModelType.Context
    @ObservedObject private var wysiwygViewModel: WysiwygComposerViewModel
    private let completionSuggestionSharedContext: CompletionSuggestionViewModelType.Context
    private let resizeAnimationDuration: Double
    
    private let sendMessageAction: (WysiwygComposerContent) -> Void
    private let showSendMediaActions: () -> Void
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @State private var isActionButtonShowing = false

    private let horizontalPadding: CGFloat = 12
    private let borderHeight: CGFloat = 40
    private let standardVerticalPadding: CGFloat = 8.0
    private let contextBannerHeight: CGFloat = 14.5

    /// Spacing applied within the VStack holding the context banner and the composer text view.
    private let verticalComponentSpacing: CGFloat = 12.0
    /// Padding for the main composer text view. Always applied on bottom.
    /// Applied on top only if no context banner is present.
    private var composerVerticalPadding: CGFloat {
        (borderHeight - wysiwygViewModel.minHeight) / 2
    }

    /// Computes the top padding to apply on the composer text view depending on context.
    private var composerTopPadding: CGFloat {
        viewModel.viewState.shouldDisplayContext ? 0 : composerVerticalPadding
    }

    /// Computes the additional height required to display the context banner.
    /// Returns 0.0 if the banner is not displayed.
    /// Note: height of the actual banner + its added standard top padding + VStack spacing
    private var additionalHeightForContextBanner: CGFloat {
        viewModel.viewState.shouldDisplayContext ? contextBannerHeight + standardVerticalPadding + verticalComponentSpacing : 0
    }

    /// Computes the total height of the composer (excluding the RTE formatting bar).
    /// This height includes the text view, as well as the context banner
    /// and user suggestion list when displayed.
    private var composerHeight: CGFloat {
        wysiwygViewModel.idealHeight
        + composerTopPadding
        + composerVerticalPadding
        // Extra padding added on top of the VStack containing the composer
        + standardVerticalPadding
        + additionalHeightForContextBanner
    }
    
    private var cornerRadius: CGFloat {
        if shouldFixRoundCorner {
            return 14
        } else {
            return borderHeight / 2
        }
    }
    
    private var shouldFixRoundCorner: Bool {
        viewModel.viewState.shouldDisplayContext || wysiwygViewModel.idealHeight > wysiwygViewModel.minHeight
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
        viewModel.focused ? theme.colors.quarterlyContent : theme.colors.quinaryContent
    }
    
    private var formatItems: [FormatItem] {
        return FormatType.allCases
            // Exclude indent type outside of lists.
            .filter { wysiwygViewModel.isInList || !$0.isIndentType }
            .map { type in
                FormatItem(
                    type: type,
                    state: wysiwygViewModel.actionStates[type.composerAction] ?? .disabled
                )
            }
    }
    
    private var composerContainer: some View {
        let rect = RoundedRectangle(cornerRadius: cornerRadius)
        return VStack(spacing: verticalComponentSpacing) {
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
                .frame(height: contextBannerHeight)
                .padding(.top, standardVerticalPadding)
                .padding(.horizontal, horizontalPadding)
            }
            HStack(alignment: shouldFixRoundCorner ? .top : .center, spacing: 0) {
                WysiwygComposerView(
                    focused: $viewModel.focused,
                    viewModel: wysiwygViewModel
                )
                .tintColor(theme.colors.accent)
                .placeholder(viewModel.viewState.placeholder, color: theme.colors.tertiaryContent)
                .onAppear {
                    if wysiwygViewModel.isContentEmpty {
                        wysiwygViewModel.setup()
                    }
                }
                if !viewModel.viewState.isMinimiseForced {
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
            .padding(.top, composerTopPadding)
            .padding(.bottom, composerVerticalPadding)
        }
        .clipShape(rect)
        .overlay(rect.stroke(borderColor, lineWidth: 1))
        .animation(.easeInOut(duration: resizeAnimationDuration), value: wysiwygViewModel.idealHeight)
        .padding(.top, standardVerticalPadding)
        .onTapGesture {
            if viewModel.focused {
                viewModel.focused = true
            }
        }
    }
    
    private var sendMediaButton: some View {
        return Button {
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
    }
    
    private var sendButton: some View {
        return Button {
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
    
    // MARK: Public
    
    init(
        viewModel: ComposerViewModelType.Context,
        wysiwygViewModel: WysiwygComposerViewModel,
        completionSuggestionSharedContext: CompletionSuggestionViewModelType.Context,
        resizeAnimationDuration: Double,
        sendMessageAction: @escaping (WysiwygComposerContent) -> Void,
        showSendMediaActions: @escaping () -> Void) {
            self.viewModel = viewModel
            self.wysiwygViewModel = wysiwygViewModel
            self.completionSuggestionSharedContext = completionSuggestionSharedContext
            self.resizeAnimationDuration = resizeAnimationDuration
            self.sendMessageAction = sendMessageAction
            self.showSendMediaActions = showSendMediaActions
        }
    
    var body: some View {
        VStack(spacing: 8) {
            if wysiwygViewModel.maximised {
                RoundedRectangle(cornerRadius: 4)
                    .fill(theme.colors.quinaryContent)
                    .frame(width: 36, height: 5)
                    .padding(.top, 10)
            }
            VStack {
                HStack(alignment: .bottom, spacing: 0) {
                    if !viewModel.viewState.textFormattingEnabled {
                        sendMediaButton
                            .padding(.bottom, 1)
                    }
                    composerContainer
                    if !viewModel.viewState.textFormattingEnabled {
                        sendButton
                            .padding(.bottom, 1)
                    }
                }
                if wysiwygViewModel.maximised {
                    CompletionSuggestionList(viewModel: completionSuggestionSharedContext, showBackgroundShadow: false)
                }
            }
            .frame(height: composerHeight)
            if viewModel.viewState.textFormattingEnabled {
                HStack(alignment: .center, spacing: 0) {
                    sendMediaButton
                    FormattingToolbar(formatItems: formatItems) { type in
                        if type.action == .link {
                            storeCurrentSelection()
                            sendLinkAction()
                        } else {
                            wysiwygViewModel.apply(type.action)
                        }
                    }
                    .frame(height: 44)
                    Spacer()
                    sendButton
                }
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, 4)
        .onChange(of: viewModel.viewState.isMinimiseForced) { newValue in
            if wysiwygViewModel.maximised && newValue {
                wysiwygViewModel.maximised = false
            }
        }
        .onChange(of: wysiwygViewModel.suggestionPattern) { newValue in
            sendMentionPattern(pattern: newValue)
        }
    }
    
    private func storeCurrentSelection() {
        viewModel.send(viewAction: .storeSelection(selection: wysiwygViewModel.attributedContent.selection))
    }
    
    private func sendLinkAction() {
        let linkAction = wysiwygViewModel.getLinkAction()
        viewModel.send(viewAction: .linkTapped(linkAction: linkAction))
    }

    private func sendMentionPattern(pattern: SuggestionPattern?) {
        viewModel.send(viewAction: .suggestion(pattern: pattern))
    }
}

private extension WysiwygComposerViewModel {
    /// Return true if the selection of the composer is currently located in a list.
    var isInList: Bool {
        actionStates[.orderedList] == .reversed || actionStates[.unorderedList] == .reversed
    }
}

// MARK: Previews

struct Composer_Previews: PreviewProvider {
    static let stateRenderer = MockComposerScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
