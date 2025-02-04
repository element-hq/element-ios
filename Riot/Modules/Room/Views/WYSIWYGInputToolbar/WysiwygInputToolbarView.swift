// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Reusable
import WysiwygComposer
import HTMLParser
import SwiftUI
import Combine
import UIKit
import CoreGraphics

@objc protocol HtmlRoomInputToolbarViewProtocol: RoomInputToolbarViewProtocol {
    @objc var htmlContent: String { get set }
}

// The toolbar for editing with rich text

class WysiwygInputToolbarView: MXKRoomInputToolbarView, NibLoadable, HtmlRoomInputToolbarViewProtocol {
    // MARK: - Properties
    
    // MARK: Private
    private var keyboardHeight: CGFloat = .zero {
        didSet {
            updateTextViewHeight()
        }
    }
    private var voiceMessageToolbarView: VoiceMessageToolbarView?
    private var cancellables = Set<AnyCancellable>()
    private var heightConstraint: NSLayoutConstraint!
    private var voiceMessageBottomConstraint: NSLayoutConstraint?
    private var hostingViewController: VectorHostingController!
    private var wysiwygViewModel = WysiwygComposerViewModel(
        parserStyle: WysiwygInputToolbarView.parserStyle
    )
    /// Compute current HTML parser style for composer.
    private static var parserStyle: HTMLParserStyle {
        return HTMLParserStyle(
            textColor: ThemeService.shared().theme.colors.primaryContent,
            linkColor: ThemeService.shared().theme.colors.links,
            codeBlockStyle: BlockStyle(backgroundColor: ThemeService.shared().theme.selectedBackgroundColor,
                                       borderColor: ThemeService.shared().theme.textQuinaryColor,
                                       borderWidth: 1.0,
                                       cornerRadius: 4.0,
                                       padding: .init(horizontal: 10.0, vertical: 12.0),
                                       type: .background),
            quoteBlockStyle: BlockStyle(backgroundColor: ThemeService.shared().theme.selectedBackgroundColor,
                                        borderColor: ThemeService.shared().theme.selectedBackgroundColor,
                                        borderWidth: 0.0,
                                        cornerRadius: 0.0,
                                        padding: .init(horizontal: 25.0, vertical: 12.0),
                                        type: .side(offset: 5, width: 4)))
    }
    private var viewModel: ComposerViewModelProtocol!
    
    private var isLandscapePhone: Bool {
        let device = UIDevice.current
        return device.isPhone && device.orientation.isLandscape
    }
    
    // MARK: Public

    override var delegate: MXKRoomInputToolbarViewDelegate! {
        didSet {
            setupComposerIfNeeded()
        }
    }
    
    override var placeholder: String! {
        get {
            viewModel.placeholder
        }
        set {
            viewModel.placeholder = newValue
        }
    }
    
    override var isFocused: Bool {
        viewModel.isFocused
    }

    override var attributedTextMessage: NSAttributedString? {
        // Note: this is only interactive in plain text mode. If RTE is enabled,
        // APIs from the composer view model should be used.
        get {
            guard !self.textFormattingEnabled else {
                MXLog.failure("[WysiwygInputToolbarView] Trying to get attributedTextMessage in RTE mode")
                return nil
            }
            return self.wysiwygViewModel.textView.attributedText
        }
        set {
            guard !self.textFormattingEnabled else {
                MXLog.failure("[WysiwygInputToolbarView] Trying to set attributedTextMessage in RTE mode")
                return
            }
            self.wysiwygViewModel.textView.attributedText = newValue
        }
    }

    override var defaultFont: UIFont {
        return UIFont.preferredFont(forTextStyle: .body)
    }
    
    var isMaximised: Bool {
        wysiwygViewModel.maximised
    }
    
    var idealHeight: CGFloat {
        get {
            wysiwygViewModel.idealHeight
        }
        set {
            wysiwygViewModel.idealHeight = newValue
        }
    }
    
    var compressedHeight: CGFloat {
        wysiwygViewModel.compressedHeight
    }
    
    var maxExpandedHeight: CGFloat {
        wysiwygViewModel.maxExpandedHeight
    }
    
    var maxCompressedHeight: CGFloat {
        wysiwygViewModel.maxCompressedHeight
    }
    
    override func paste(_ sender: Any?) {
        let pasteboard = MXKPasteboardManager.shared.pasteboard
        let types = pasteboard.types.map { UTI(rawValue: $0) }
        
        // Minimise the composer and dismiss the keyboard if it's an image, a video or a file
        if types.contains(where: { $0.conforms(to: .image) || $0.conforms(to: .movie) || $0.conforms(to: .video) || $0.conforms(to: .application) }) {
            wysiwygViewModel.maximised = false
            DispatchQueue.main.async {
                self.viewModel.dismissKeyboard()
            }
        }
        super.paste(sender)
    }
    
    // MARK: - Setup
    
    override class func instantiate() -> MXKRoomInputToolbarView! {
        return loadFromNib()
    }
    
    private weak var toolbarViewDelegate: RoomInputToolbarViewDelegate? {
        return (delegate as? RoomInputToolbarViewDelegate) ?? nil
    }

    private var permalinkReplacer: MentionReplacer? {
        return (delegate as? MentionReplacer)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        setupComposerIfNeeded()
    }
    
    override func customizeRendering() {
        super.customizeRendering()
        self.backgroundColor = .clear
    }
    
    override func dismissKeyboard() {
        self.viewModel.dismissKeyboard()
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        self.wysiwygViewModel.textView.becomeFirstResponder()
    }
    
    override func dismissValidationView(_ validationView: MXKImageView!) {
        super.dismissValidationView(validationView)
        if isMaximised {
            showKeyboard()
        }
    }

    override func setPartialContent(_ attributedTextMessage: NSAttributedString) {
        let content: String
        if #available(iOS 15.0, *) {
            content = PillsFormatter.stringByReplacingPills(in: attributedTextMessage, mode: .markdown)
        } else {
            content = attributedTextMessage.string
        }
        self.wysiwygViewModel.setMarkdownContent(content)
    }
    
    func showKeyboard() {
        self.wysiwygViewModel.textView.becomeFirstResponder()
        self.viewModel.showKeyboard()
    }
    
    func minimise() {
        wysiwygViewModel.maximised = false
    }
    
    func performLinkOperation(_ linkOperation: WysiwygLinkOperation) {
        if let selectionToRestore = viewModel.selectionToRestore {
            wysiwygViewModel.select(range: selectionToRestore)
        }
        wysiwygViewModel.applyLinkOperation(linkOperation)
    }

    func mention(_ member: MXRoomMember) {
        guard let userId = member.userId else {
            return
        }
        
        let displayName = member.displayname ?? userId
        
        self.wysiwygViewModel.setMention(url: MXTools.permalinkToUser(withUserId: userId),
                                         name: displayName,
                                         mentionType: .user)
    }

    func command(_ command: String) {
        self.wysiwygViewModel.setCommand(name: command)
    }
    
    // MARK: - Private

    private func setupComposerIfNeeded() {
        guard hostingViewController == nil,
              let toolbarViewDelegate,
              let permalinkReplacer else { return }

        viewModel = ComposerViewModel(
            initialViewState: ComposerViewState(textFormattingEnabled: RiotSettings.shared.enableWysiwygTextFormatting,
                                                isLandscapePhone: isLandscapePhone,
                                                bindings: ComposerBindings(focused: false)))

        viewModel.callback = { [weak self] result in
            self?.handleViewModelResult(result)
        }
        wysiwygViewModel.plainTextMode = !RiotSettings.shared.enableWysiwygTextFormatting
        wysiwygViewModel.mentionReplacer = permalinkReplacer

        inputAccessoryViewForKeyboard = UIView(frame: .zero)

        let composer = Composer(
            viewModel: viewModel.context,
            wysiwygViewModel: wysiwygViewModel,
            completionSuggestionSharedContext: toolbarViewDelegate.completionSuggestionContext().context,
            resizeAnimationDuration: Double(kResizeComposerAnimationDuration),
            sendMessageAction: { [weak self] content in
            guard let self = self else { return }
            self.sendWysiwygMessage(content: content)
        }, showSendMediaActions: { [weak self]  in
            guard let self = self else { return }
            self.showSendMediaActions()
        })
            .introspectTextView { [weak self] textView in
                guard let self = self else { return }
                textView.inputAccessoryView = self.inputAccessoryViewForKeyboard
            }
            .environmentObject(AvatarViewModel(avatarService: AvatarService(mediaManager: toolbarViewDelegate.mediaManager())))

        hostingViewController = VectorHostingController(rootView: composer)
        hostingViewController.publishHeightChanges = true
        let height = hostingViewController.sizeThatFits(in: CGSize(width: self.frame.width, height: UIView.layoutFittingExpandedSize.height)).height
        let subView: UIView = hostingViewController.view
        self.addSubview(subView)

        self.translatesAutoresizingMaskIntoConstraints = false
        subView.translatesAutoresizingMaskIntoConstraints = false
        heightConstraint = subView.heightAnchor.constraint(equalToConstant: height)
        NSLayoutConstraint.activate([
            heightConstraint,
            subView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            subView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            subView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])

        cancellables = [
            hostingViewController.heightPublisher
                .removeDuplicates()
                .sink(receiveValue: { [weak self] idealHeight in
                    guard let self = self else { return }
                    self.updateToolbarHeight(wysiwygHeight: idealHeight)
                }),
            // Required to update the view constraints after minimise/maximise is tapped
            wysiwygViewModel.$idealHeight
                .removeDuplicates()
                .sink { [weak hostingViewController] _ in
                    hostingViewController?.view.setNeedsLayout()
                },

            wysiwygViewModel.$maximised
                .dropFirst()
                .removeDuplicates()
                .sink { [weak self] value in
                    guard let self = self else { return }
                    self.toolbarViewDelegate?.didChangeMaximisedState(value)
                    self.hostingViewController.view.layer.cornerRadius = value ? 20 : 0
                    if !value {
                        self.voiceMessageBottomConstraint?.constant = 2
                    }
                },

            wysiwygViewModel.$plainTextContent
                .removeDuplicates()
                .dropFirst()
                .sink { [weak self] attributed in
                    // Note: filter out `plainTextMode` being off, as switching to RTE will trigger this
                    // publisher with empty content. This avoids saving the partial text message
                    // or trying to compute suggestion from this empty content.
                    guard let self, self.wysiwygViewModel.plainTextMode else { return }
                    self.textMessage = attributed.string
                    self.toolbarViewDelegate?.roomInputToolbarViewDidChangeTextMessage(self)
                    self.toolbarViewDelegate?.roomInputToolbarView?(self, shouldStorePartialContent: attributed)
                },
            
            wysiwygViewModel.$attributedContent
                .removeDuplicates(by: {
                    $0.text == $1.text
                })
                .dropFirst()
                .sink { [weak self] _ in
                    // Note: filter out `plainTextMode` being on, as switching to plain text mode will trigger this
                    // publisher with empty content. This avoids saving the partial text message
                    // or trying to compute suggestion from this empty content.
                    guard let self, !self.wysiwygViewModel.plainTextMode else { return }
                    let markdown = self.wysiwygViewModel.content.markdown
                    let attributed = NSAttributedString(string: markdown, attributes: [.font: self.defaultFont])
                    self.toolbarViewDelegate?.roomInputToolbarView?(self, shouldStorePartialContent: attributed)
                }
        ]

        update(theme: ThemeService.shared().theme)
        registerThemeServiceDidChangeThemeNotification()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(self, selector: #selector(deviceDidRotate), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            keyboardHeight = keyboardRectangle.height
            if self.isMaximised {
                self.voiceMessageBottomConstraint?.constant = keyboardHeight - (window?.safeAreaInsets.bottom ?? 0) + 2
            } else {
                self.voiceMessageBottomConstraint?.constant = 2
            }
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        if self.isMaximised {
            self.voiceMessageBottomConstraint?.constant = 2
        }
    }
    
    @objc private func deviceDidRotate(_ notification: Notification) {
        viewModel.isLandscapePhone = isLandscapePhone
        DispatchQueue.main.async {
            self.updateTextViewHeight()
        }
    }
    
    private func updateToolbarHeight(wysiwygHeight: CGFloat) {
        self.heightConstraint.constant = wysiwygHeight
        toolbarViewDelegate?.roomInputToolbarView?(self, heightDidChanged: wysiwygHeight, completion: nil)
    }
    
    private func sendWysiwygMessage(content: WysiwygComposerContent) {
        if content.markdown.prefix(while: { $0 == "/" }).count == 1 {
            let commandText: String
            if content.markdown.hasPrefix(MXKSlashCommand.emote.cmd) {
                // `/me` command works with markdown content
                commandText = content.markdown
            } else if #available(iOS 15.0, *) {
                // Other commands should see pills replaced by matrix identifiers
                commandText = PillsFormatter.stringByReplacingPills(in: self.wysiwygViewModel.textView.attributedText, mode: .identifier)
            } else {
                // Without Pills support, just use the raw text for command
                commandText = self.wysiwygViewModel.textView.text
            }

            // Fix potential command failures due to trailing characters
            // or NBSP that are not properly handled by the command interpreter
            let sanitizedCommand = commandText
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: String.nbsp, with: " ")

            delegate?.roomInputToolbarView?(self, sendCommand: sanitizedCommand)
        } else {
            delegate?.roomInputToolbarView?(self, sendFormattedTextMessage: content.html, withRawText: content.markdown)
        }

        if isMaximised {
            minimise()
        }
    }
    
    private func showSendMediaActions() {
        delegate?.roomInputToolbarViewShowSendMediaActions?(self)
    }
    
    private func handleViewModelResult(_ result: ComposerViewModelResult) {
        switch result {
        case .cancel:
            toolbarViewDelegate?.roomInputToolbarViewDidTapCancel(self)
        case let .contentDidChange(isEmpty):
            setVoiceMessageToolbarIsHidden(!isEmpty)
        case let .linkTapped(linkAction):
            toolbarViewDelegate?.didSendLinkAction(LinkActionWrapper(linkAction))
        case let .suggestion(pattern):
            toolbarViewDelegate?.didDetectTextPattern(SuggestionPatternWrapper(pattern))
        }
    }
    
    private func setVoiceMessageToolbarIsHidden(_ isHidden: Bool) {
        guard let voiceMessageToolbarView = voiceMessageToolbarView else { return }
        UIView.transition(
            with: voiceMessageToolbarView, duration: 0.15,
            options: .transitionCrossDissolve,
            animations: {
                voiceMessageToolbarView.isHidden = isHidden
            }
        )
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func update(theme: Theme) {
        hostingViewController.view.backgroundColor = theme.colors.background
        wysiwygViewModel.parserStyle = WysiwygInputToolbarView.parserStyle
    }
    
    private func updateTextViewHeight() {
        let height = UIScreen.main.bounds.height
        let barOffset: CGFloat = 68
        let toolbarHeight: CGFloat = sendMode == .send ? 96 : 110
        let finalHeight = height - keyboardHeight - toolbarHeight - barOffset
        wysiwygViewModel.maxExpandedHeight = finalHeight
        if finalHeight < 200 {
            wysiwygViewModel.maxCompressedHeight = finalHeight > wysiwygViewModel.minHeight ? finalHeight : wysiwygViewModel.minHeight
        } else {
            wysiwygViewModel.maxCompressedHeight = 200
        }
    }
    
    // MARK: - HtmlRoomInputToolbarViewProtocol
    var isEncryptionEnabled = false {
        didSet {
            updatePlaceholderText()
        }
    }
    
    /// The current html content of the composer
    var htmlContent: String {
        get {
            wysiwygViewModel.content.html
        }
        set {
            wysiwygViewModel.setHtmlContent(newValue)
        }
    }
    
    /// The display name to show when in edit/reply
    var eventSenderDisplayName: String! {
        get {
            viewModel.eventSenderDisplayName
        }
        set {
            viewModel.eventSenderDisplayName = newValue
        }
    }
    
    /// Whether the composer is in send, reply or edit mode.
    var sendMode: RoomInputToolbarViewSendMode {
        get {
            viewModel.sendMode.legacySendMode
        }
        set {
            viewModel.sendMode = ComposerSendMode(from: newValue)
            updatePlaceholderText()
            updateTextViewHeight()
        }
    }
    
    /// Whether text formatting is currently enabled in the composer.
    var textFormattingEnabled: Bool {
        get {
            self.viewModel.textFormattingEnabled
        }
        set {
            self.viewModel.textFormattingEnabled = newValue
            self.wysiwygViewModel.plainTextMode = !newValue
        }
    }
    
    /// Add the voice message toolbar to the composer
    /// - Parameter voiceMessageToolbarView: the voice message toolbar UIView
    func setVoiceMessageToolbarView(_ voiceMessageToolbarView: UIView!) {
        if let voiceMessageToolbarView = voiceMessageToolbarView as? VoiceMessageToolbarView {
            self.voiceMessageToolbarView = voiceMessageToolbarView
            voiceMessageToolbarView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.deactivate(voiceMessageToolbarView.containersTopConstraints)
            addSubview(voiceMessageToolbarView)
            let bottomConstraint = hostingViewController.view.bottomAnchor.constraint(equalTo: voiceMessageToolbarView.bottomAnchor, constant: 2)
            voiceMessageBottomConstraint = bottomConstraint
            NSLayoutConstraint.activate(
                [
                    hostingViewController.view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: voiceMessageToolbarView.topAnchor),
                    hostingViewController.view.safeAreaLayoutGuide.leftAnchor.constraint(equalTo: voiceMessageToolbarView.leftAnchor),
                    bottomConstraint,
                    hostingViewController.view.safeAreaLayoutGuide.rightAnchor.constraint(equalTo: voiceMessageToolbarView.rightAnchor)
                ]
            )
        } else {
            self.voiceMessageToolbarView?.removeFromSuperview()
            self.voiceMessageToolbarView = nil
            self.voiceMessageBottomConstraint?.isActive = false
            self.voiceMessageBottomConstraint = nil
        }
    }
    
    func toolbarHeight() -> CGFloat {
        return heightConstraint.constant
    }
}

// MARK: - LegacySendModeAdapter

fileprivate extension ComposerSendMode {
    init(from sendMode: RoomInputToolbarViewSendMode) {
        switch sendMode {
        case .reply: self = .reply
        case .edit: self = .edit
        case .createDM: self = .createDM
        default: self = .send
        }
    }
    
    var legacySendMode: RoomInputToolbarViewSendMode {
        switch self {
        case .createDM: return .createDM
        case .reply: return .reply
        case .edit: return .edit
        case .send: return .send
        }
    }
}
