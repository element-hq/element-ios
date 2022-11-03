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
    private var voiceMessageToolbarView: VoiceMessageToolbarView?
    private var cancellables = Set<AnyCancellable>()
    private var heightConstraint: NSLayoutConstraint!
    private var hostingViewController: VectorHostingController!
    private var wysiwygViewModel = WysiwygComposerViewModel(textColor: ThemeService.shared().theme.colors.primaryContent)
    private var viewModel: ComposerViewModelProtocol = ComposerViewModel(initialViewState: ComposerViewState(bindings: ComposerBindings(focused: false)))
    private var coordinator: ComposerCoordinator!
    private let transition = SheetAnimator()
    
    // MARK: Public
    
    override var placeholder: String! {
        get {
            viewModel.placeholder
        }
        set {
            viewModel.placeholder = newValue
        }
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
        
        viewModel.callback = { [weak self] result in
            self?.handleViewModelResult(result)
        }
        
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
        hostingViewController.transitioningDelegate = self
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
        
        update(theme: ThemeService.shared().theme)
        registerThemeServiceDidChangeThemeNotification()
        
        coordinator = ComposerCoordinator(hostingVC: hostingViewController, viewModel: viewModel)
        
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
                .removeDuplicates()
                .sink { [weak self] value in
                    guard let self = self else { return }
                    let presenter = ComposerBridgePresenter(coordinator: self.coordinator)
                    if value {
                        self.toolbarViewDelegate?.presentFullscreenToolbar(presenter)
                    } else {
                        presenter.dismiss(animated: true, completion: nil)
                    }
                }
        ]
    }
    
    override func customizeRendering() {
        super.customizeRendering()
        self.backgroundColor = .clear
    }
    
    override func dismissKeyboard() {
        self.viewModel.dismissKeyboard()
    }
    
    // MARK: - Private
    
    private func updateToolbarHeight(wysiwygHeight: CGFloat) {
        self.heightConstraint.constant = wysiwygHeight
        toolbarViewDelegate?.roomInputToolbarView?(self, heightDidChanged: wysiwygHeight, completion: nil)
    }
    
    private func sendWysiwygMessage(content: WysiwygComposerContent) {
        delegate?.roomInputToolbarView?(self, sendFormattedTextMessage: content.html, withRawText: content.plainText)
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
            NSLayoutConstraint.activate(
                [
                    hostingViewController.view.topAnchor.constraint(equalTo: voiceMessageToolbarView.topAnchor),
                    hostingViewController.view.leftAnchor.constraint(equalTo: voiceMessageToolbarView.leftAnchor),
                    hostingViewController.view.bottomAnchor.constraint(equalTo: voiceMessageToolbarView.bottomAnchor, constant: 4),
                    hostingViewController.view.rightAnchor.constraint(equalTo: voiceMessageToolbarView.rightAnchor)
                ]
            )
        } else {
            self.voiceMessageToolbarView?.removeFromSuperview()
            self.voiceMessageToolbarView = nil
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

extension WysiwygInputToolbarView: UIViewControllerTransitioningDelegate {
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController, source: UIViewController)
    -> UIViewControllerAnimatedTransitioning? {
        transition.originFrame = self.frame
        transition.presenting = true
        let superview = self.superview
        hostingViewController.view.removeFromSuperview()
        heightConstraint.constant = 0
        superview?.setNeedsLayout()
        return transition
    }
    
    func animationController(forDismissed dismissed: UIViewController)
    -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}

final class SheetAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let duration = 0.9
    var presenting = true
    var originFrame = CGRect.zero
    
    
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let toView = transitionContext.view(forKey: .to)!
        let sheetView = presenting ? toView : transitionContext.view(forKey: .from)!
        let initialFrame = presenting ? originFrame : sheetView.frame
        let finalFrame = presenting ? sheetView.frame : originFrame
        
        let xScaleFactor = presenting ?
        initialFrame.width / finalFrame.width :
        finalFrame.width / initialFrame.width
        
        let yScaleFactor = presenting ?
        initialFrame.height / finalFrame.height :
        finalFrame.height / initialFrame.height
        let scaleTransform = CGAffineTransform(scaleX: xScaleFactor, y: yScaleFactor)
        
        if presenting {
            sheetView.transform = scaleTransform
            sheetView.center = CGPoint(
                x: initialFrame.midX,
                y: initialFrame.midY)
            sheetView.clipsToBounds = true
        }
        
        sheetView.layer.cornerRadius = presenting ? 20.0 : 0.0
        sheetView.layer.masksToBounds = true
        
        containerView.addSubview(toView)
        containerView.bringSubviewToFront(sheetView)
        
        UIView.animate(
            withDuration: duration,
            delay: 0.0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.2,
            animations: {
                sheetView.transform = self.presenting ? .identity : scaleTransform
                sheetView.center = CGPoint(x: finalFrame.midX, y: finalFrame.midY)
                sheetView.layer.cornerRadius = !self.presenting ? 20.0 : 0.0
            }, completion: { _ in
                transitionContext.completeTransition(true)
            })
    }
}
