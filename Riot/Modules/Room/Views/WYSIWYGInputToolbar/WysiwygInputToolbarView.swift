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

import Foundation
import Reusable
import WysiwygComposer
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
    private var wysiwygViewModel = WysiwygComposerViewModel(textColor: ThemeService.shared().theme.colors.primaryContent)
    private var viewModel: ComposerViewModelProtocol!
    
    private var isLandscapePhone: Bool {
        let device = UIDevice.current
        return device.isPhone && device.orientation.isLandscape
    }
    
    // MARK: Public
    
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
    
    // MARK: - Setup
    
    override class func instantiate() -> MXKRoomInputToolbarView! {
        return loadFromNib()
    }
    
    private weak var toolbarViewDelegate: RoomInputToolbarViewDelegate? {
        return (delegate as? RoomInputToolbarViewDelegate) ?? nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        viewModel = ComposerViewModel(
            initialViewState: ComposerViewState(textFormattingEnabled: RiotSettings.shared.enableWysiwygTextFormatting,
                                                isLandscapePhone: isLandscapePhone, bindings: ComposerBindings(focused: false)))
        
        viewModel.callback = { [weak self] result in
            self?.handleViewModelResult(result)
        }
        wysiwygViewModel.plainTextMode = !RiotSettings.shared.enableWysiwygTextFormatting
        
        inputAccessoryViewForKeyboard = UIView(frame: .zero)
        
        let composer = Composer(
            viewModel: viewModel.context,
            wysiwygViewModel: wysiwygViewModel,
            resizeAnimationDuration: Double(kResizeComposerAnimationDuration),
            sendMessageAction: { [weak self] content in
            guard let self = self else { return }
            self.sendWysiwygMessage(content: content)
        }, showSendMediaActions: { [weak self]  in
            guard let self = self else { return }
            self.showSendMediaActions()
        }).introspectTextView { [weak self] textView in
            guard let self = self else { return }
            textView.inputAccessoryView = self.inputAccessoryViewForKeyboard
        }
        
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
    
    override func customizeRendering() {
        super.customizeRendering()
        self.backgroundColor = .clear
    }
    
    override func dismissKeyboard() {
        self.viewModel.dismissKeyboard()
    }
    
    override func dismissValidationView(_ validationView: MXKImageView!) {
        super.dismissValidationView(validationView)
        if isMaximised {
            showKeyboard()
        }
    }
    
    func showKeyboard() {
        self.viewModel.showKeyboard()
    }
    
    func minimise() {
        wysiwygViewModel.maximised = false
    }
    
    // MARK: - Private
    
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
        delegate?.roomInputToolbarView?(self, sendFormattedTextMessage: content.html, withRawText: content.markdown)
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
            self.toolbarViewDelegate?.roomInputToolbarViewDidTapCancel(self)
        case let .contentDidChange(isEmpty):
            setVoiceMessageToolbarIsHidden(!isEmpty)
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
        wysiwygViewModel.textColor = theme.colors.primaryContent
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
