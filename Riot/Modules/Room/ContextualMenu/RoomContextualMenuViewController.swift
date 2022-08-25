/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit

@objc protocol RoomContextualMenuViewControllerDelegate: AnyObject {
    func roomContextualMenuViewControllerDidTapBackgroundOverlay(_ viewController: RoomContextualMenuViewController)
}

@objcMembers
final class RoomContextualMenuViewController: UIViewController, Themable {
    // MARK: - Constants
    
    private enum Constants {
        static let reactionsMenuViewVerticalMargin: CGFloat = 10.0
        static let reactionsMenuViewHiddenScale: CGFloat = 0.97
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private var backgroundOverlayView: UIView!
    @IBOutlet private var menuToolbarView: RoomContextualMenuToolbarView!
    
    @IBOutlet private var menuToolbarViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var menuToolbarViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private var reactionsMenuContainerView: UIView!
    @IBOutlet private var reactionsMenuViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var reactionsMenuViewBottomConstraint: NSLayoutConstraint!
    
    // MARK: Private
    
    private var theme: Theme!
    private var contextualMenuItems: [RoomContextualMenuItem] = []
    private var reactionsMenuViewModel: ReactionsMenuViewModel?
    
    private weak var reactionsMenuView: ReactionsMenuView?
    
    private var reactionsMenuViewBottomStartConstraintConstant: CGFloat?
    private var reactionsMenuViewBottomEndConstraintConstant: CGFloat?
    
    private var hiddenToolbarViewBottomConstant: CGFloat {
        let bottomSafeAreaHeight: CGFloat
        
        bottomSafeAreaHeight = view.safeAreaInsets.bottom
        
        return -(menuToolbarViewHeightConstraint.constant + bottomSafeAreaHeight)
    }
    
    private var shouldPresentReactionsMenu: Bool {
        reactionsMenuContainerView.isHidden == false
    }
    
    // MARK: Public
    
    var contentToReactFrame: CGRect?
    var shouldPerformTappedReactionAnimation: Bool {
        self.reactionsMenuView?.reactionHasBeenTapped ?? false
    }
    
    weak var delegate: RoomContextualMenuViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate() -> RoomContextualMenuViewController {
        let viewController = StoryboardScene.RoomContextualMenuViewController.initialScene.instantiate()
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        backgroundOverlayView.isUserInteractionEnabled = true
        setupBackgroundOverlayGestureRecognizers()
        
        updateViews()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
    }
    
    // MARK: - Public
    
    func update(contextualMenuItems: [RoomContextualMenuItem], reactionsMenuViewModel: ReactionsMenuViewModel?) {
        self.contextualMenuItems = contextualMenuItems
        self.reactionsMenuViewModel = reactionsMenuViewModel
        if isViewLoaded {
            updateViews()
        }
    }
    
    func showMenuToolbar() {
        menuToolbarViewBottomConstraint.constant = 0
        menuToolbarView.alpha = 1
        
        // Force VoiceOver to focus on the menu bar actions
        UIAccessibility.post(notification: .screenChanged, argument: menuToolbarView)
    }
    
    func hideMenuToolbar() {
        menuToolbarViewBottomConstraint.constant = hiddenToolbarViewBottomConstant
        menuToolbarView.alpha = 0
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
    
    func prepareReactionsMenuAnimations() {
        guard let frame = contentToReactFrame, frame.equalTo(CGRect.null) == false else {
            return
        }
        
        let menuHeight = reactionsMenuViewHeightConstraint.constant
        let verticalMargin = Constants.reactionsMenuViewVerticalMargin
        
        let reactionsMenuViewBottomStartConstraintConstant: CGFloat?
        let reactionsMenuViewBottomEndConstraintConstant: CGFloat?
        
        // Try to display the menu at the top of the message first
        // Then, try at the bottom
        // Else, keep the position defined in the storyboard
        if frame.origin.y - verticalMargin >= menuHeight {
            let menuViewBottomY = frame.origin.y - verticalMargin
            reactionsMenuViewBottomStartConstraintConstant = menuViewBottomY + menuHeight / 2
            reactionsMenuViewBottomEndConstraintConstant = menuViewBottomY
        } else {
            let frameBottomY = frame.origin.y + frame.size.height + verticalMargin
            let visibleViewHeight = view.frame.size.height - menuToolbarView.frame.size.height
            
            if frameBottomY + menuHeight < visibleViewHeight {
                let menuViewBottomY = frameBottomY + menuHeight
                
                reactionsMenuViewBottomEndConstraintConstant = menuViewBottomY
                reactionsMenuViewBottomStartConstraintConstant = menuViewBottomY - menuHeight / 2
            } else {
                reactionsMenuViewBottomEndConstraintConstant = nil
                reactionsMenuViewBottomStartConstraintConstant = nil
            }
        }
        
        self.reactionsMenuViewBottomStartConstraintConstant = reactionsMenuViewBottomStartConstraintConstant
        self.reactionsMenuViewBottomEndConstraintConstant = reactionsMenuViewBottomEndConstraintConstant
        
        reactionsMenuContainerView.isHidden = false
    }
    
    func showReactionsMenu() {
        guard shouldPresentReactionsMenu, let reactionsMenuView = reactionsMenuView else {
            return
        }
        
        if let reactionsMenuViewBottomEndConstraintConstant = reactionsMenuViewBottomEndConstraintConstant {
            reactionsMenuViewBottomConstraint.constant = reactionsMenuViewBottomEndConstraintConstant
        }
        
        reactionsMenuView.alpha = 1
        reactionsMenuContainerView.transform = CGAffineTransform.identity
    }
    
    func hideReactionsMenu() {
        guard shouldPresentReactionsMenu, let reactionsMenuView = reactionsMenuView else {
            return
        }
        
        if let reactionsMenuViewBottomStartConstraintConstant = reactionsMenuViewBottomStartConstraintConstant {
            reactionsMenuViewBottomConstraint.constant = reactionsMenuViewBottomStartConstraintConstant
        }
        
        reactionsMenuView.alpha = 0
        
        let transformScale = Constants.reactionsMenuViewHiddenScale
        reactionsMenuContainerView.transform = CGAffineTransform(scaleX: transformScale, y: transformScale)
    }
    
    func selectedReactionAnimationsIntructionsPart1() {
        reactionsMenuView?.selectionAnimationInstructionPart1()
    }
    
    func selectedReactionAnimationsIntructionsPart2() {
        reactionsMenuView?.selectionAnimationInstructionPart2()
    }
    
    func update(theme: Theme) {
        menuToolbarView.update(theme: theme)
        reactionsMenuView?.update(theme: theme)
    }
    
    // MARK: - Private
    
    private func updateViews() {
        menuToolbarView.fill(contextualMenuItems: contextualMenuItems)
        
        let hideReactionMenu: Bool
        
        if let reactionsMenuViewModel = reactionsMenuViewModel {
            hideReactionMenu = false
            updateReactionsMenu(with: reactionsMenuViewModel)
        } else {
            hideReactionMenu = true
        }
        
        reactionsMenuContainerView.isHidden = hideReactionMenu
    }
    
    private func updateReactionsMenu(with viewModel: ReactionsMenuViewModel) {
        if reactionsMenuContainerView.subviews.isEmpty {
            let reactionsMenuView = ReactionsMenuView.loadFromNib()
            reactionsMenuContainerView.vc_addSubViewMatchingParent(reactionsMenuView)
            reactionsMenuView.update(theme: theme)
            self.reactionsMenuView = reactionsMenuView
        }
        
        reactionsMenuView?.viewModel = viewModel
    }
    
    private func setupBackgroundOverlayGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handle(gestureRecognizer:)))
        tapGestureRecognizer.delegate = self
        
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handle(gestureRecognizer:)))
        swipeGestureRecognizer.direction = [.down, .up]
        swipeGestureRecognizer.delegate = self
        
        backgroundOverlayView.addGestureRecognizer(tapGestureRecognizer)
        backgroundOverlayView.addGestureRecognizer(swipeGestureRecognizer)
    }
    
    @objc private func handle(gestureRecognizer: UIGestureRecognizer) {
        delegate?.roomContextualMenuViewControllerDidTapBackgroundOverlay(self)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension RoomContextualMenuViewController: UIGestureRecognizerDelegate {
    // Avoid triggering background overlay gesture recognizers when touching reactions menu
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        touch.vc_isInside(view: reactionsMenuContainerView) == false
    }
}
