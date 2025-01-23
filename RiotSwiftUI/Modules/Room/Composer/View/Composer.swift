//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
    @FocusState private var focused: Bool

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

    /// the total height of the composer (excluding the RTE formatting bar).
    @State private var composerHeight: CGFloat = .zero
    
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
    
    private var toggleButtonAccessibilityLabel: String {
        wysiwygViewModel.maximised ? VectorL10n.wysiwygComposerActionMinimiseAction : VectorL10n.wysiwygComposerActionMaximiseAction
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
                // Use a GeometryReader to force the composer to fill the HStack
                GeometryReader { _ in
                    WysiwygComposerView(
                        placeholder: viewModel.viewState.placeholder ?? "",
                        viewModel: wysiwygViewModel,
                        itemProviderHelper: nil,
                        keyCommands: keyCommands,
                        pasteHandler: nil
                    )
                    .clipped()
                    .tint(theme.colors.accent)
                    .focused($focused)
                    .onChange(of: focused) { newValue in
                        viewModel.focused = newValue
                    }
                    .onChange(of: viewModel.focused) { newValue in
                        guard focused != newValue else { return }
                        focused = newValue
                    }
                    .onAppear {
                        if wysiwygViewModel.isContentEmpty {
                            wysiwygViewModel.setup()
                        }
                    }
                }
                
                if !viewModel.viewState.isMinimiseForced {
                    Button {
                        viewModel.focused = true
                        // Use a dispatched block so the focus state will be up to date when the composer size changes.
                        DispatchQueue.main.async {
                            wysiwygViewModel.maximised.toggle()
                        }
                    } label: {
                        Image(toggleButtonImageName)
                            .resizable()
                            .foregroundColor(theme.colors.tertiaryContent)
                            .frame(width: 16, height: 16)
                    }
                    .accessibilityIdentifier(toggleButtonAcccessibilityIdentifier)
                    .accessibilityLabel(toggleButtonAccessibilityLabel)
                    .padding(.leading, 12)
                    .padding(.trailing, 4)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, composerTopPadding)
            .padding(.bottom, composerVerticalPadding)
            .layoutPriority(1)
        }
        .clipShape(rect)
        .overlay(rect.stroke(borderColor, lineWidth: 1))
        .animation(.easeInOut(duration: resizeAnimationDuration), value: wysiwygViewModel.idealHeight)
        .padding(.top, standardVerticalPadding)
        .onTapGesture {
            viewModel.focused = true
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
    
    var keyCommands: [WysiwygKeyCommand] {
        [
            .enter {
                sendMessageAction(wysiwygViewModel.content)
                wysiwygViewModel.clearContent()
            }
        ]
    }
    
    /// Computes the total height of the composer (excluding the RTE formatting bar).
    /// This height includes the text view, as well as the context banner
    /// and user suggestion list when displayed.
    private func updateComposerHeight(idealHeight: CGFloat) {
        composerHeight = idealHeight
            + composerTopPadding
            + composerVerticalPadding
            // Extra padding added on top of the VStack containing the composer
            + standardVerticalPadding
            + additionalHeightForContextBanner
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
        .onChange(of: wysiwygViewModel.idealHeight) { newValue in
            updateComposerHeight(idealHeight: newValue)
        }
        .onChange(of: viewModel.viewState.shouldDisplayContext) { _ in
            updateComposerHeight(idealHeight: wysiwygViewModel.idealHeight)
        }
        .task {
            updateComposerHeight(idealHeight: wysiwygViewModel.idealHeight)
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
