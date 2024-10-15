/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
    
    @IBOutlet private weak var backgroundOverlayView: UIView!
    @IBOutlet private weak var menuToolbarView: RoomContextualMenuToolbarView!
    
    @IBOutlet private weak var menuToolbarViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var menuToolbarViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var reactionsMenuContainerView: UIView!
    @IBOutlet private weak var reactionsMenuViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var reactionsMenuViewBottomConstraint: NSLayoutConstraint!
    
    // MARK: Private
    
    private var theme: Theme!
    private var contextualMenuItems: [RoomContextualMenuItem] = []
    private var reactionsMenuViewModel: ReactionsMenuViewModel?
    
    private weak var reactionsMenuView: ReactionsMenuView?
    
    private var reactionsMenuViewBottomStartConstraintConstant: CGFloat?
    private var reactionsMenuViewBottomEndConstraintConstant: CGFloat?
    
    private var hiddenToolbarViewBottomConstant: CGFloat {
        let bottomSafeAreaHeight: CGFloat
        
        bottomSafeAreaHeight = self.view.safeAreaInsets.bottom
        
        return -(self.menuToolbarViewHeightConstraint.constant + bottomSafeAreaHeight)
    }
    
    private var shouldPresentReactionsMenu: Bool {
        return self.reactionsMenuContainerView.isHidden == false
    }
    
    // MARK: Public
    
    var contentToReactFrame: CGRect?
    var shouldPerformTappedReactionAnimation: Bool {
        return self.reactionsMenuView?.reactionHasBeenTapped ?? false
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

        self.backgroundOverlayView.isUserInteractionEnabled = true
        self.setupBackgroundOverlayGestureRecognizers()
        
        self.updateViews()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
    }
    
    // MARK: - Public
    
    func update(contextualMenuItems: [RoomContextualMenuItem], reactionsMenuViewModel: ReactionsMenuViewModel?) {
        self.contextualMenuItems = contextualMenuItems
        self.reactionsMenuViewModel = reactionsMenuViewModel
        if self.isViewLoaded {
            self.updateViews()
        }
    }
    
    func showMenuToolbar() {
        self.menuToolbarViewBottomConstraint.constant = 0
        self.menuToolbarView.alpha = 1
        
        // Force VoiceOver to focus on the menu bar actions
        UIAccessibility.post(notification: .screenChanged, argument: self.menuToolbarView)
    }
    
    func hideMenuToolbar() {
        self.menuToolbarViewBottomConstraint.constant = self.hiddenToolbarViewBottomConstant
        self.menuToolbarView.alpha = 0
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
    
    func prepareReactionsMenuAnimations() {
        guard let frame = self.contentToReactFrame, frame.equalTo(CGRect.null) == false else {
            return
        }
        
        let menuHeight = self.reactionsMenuViewHeightConstraint.constant
        let verticalMargin = Constants.reactionsMenuViewVerticalMargin
        
        let reactionsMenuViewBottomStartConstraintConstant: CGFloat?
        let reactionsMenuViewBottomEndConstraintConstant: CGFloat?
        
        // Try to display the menu at the top of the message first
        // Then, try at the bottom
        // Else, keep the position defined in the storyboard
        if frame.origin.y - verticalMargin >= menuHeight {
            let menuViewBottomY = frame.origin.y - verticalMargin
            reactionsMenuViewBottomStartConstraintConstant = menuViewBottomY + menuHeight/2
            reactionsMenuViewBottomEndConstraintConstant = menuViewBottomY
        } else {
            let frameBottomY = frame.origin.y + frame.size.height + verticalMargin
            let visibleViewHeight = self.view.frame.size.height - self.menuToolbarView.frame.size.height
            
            if frameBottomY + menuHeight < visibleViewHeight {
                let menuViewBottomY = frameBottomY + menuHeight
                
                reactionsMenuViewBottomEndConstraintConstant = menuViewBottomY
                reactionsMenuViewBottomStartConstraintConstant = menuViewBottomY - menuHeight/2
            } else {
                reactionsMenuViewBottomEndConstraintConstant = nil
                reactionsMenuViewBottomStartConstraintConstant = nil
            }
        }
        
        self.reactionsMenuViewBottomStartConstraintConstant = reactionsMenuViewBottomStartConstraintConstant
        self.reactionsMenuViewBottomEndConstraintConstant = reactionsMenuViewBottomEndConstraintConstant
        
        self.reactionsMenuContainerView.isHidden = false
    }
    
    func showReactionsMenu() {
        guard self.shouldPresentReactionsMenu, let reactionsMenuView = self.reactionsMenuView else {
            return
        }
        
        if let reactionsMenuViewBottomEndConstraintConstant = self.reactionsMenuViewBottomEndConstraintConstant {
            self.reactionsMenuViewBottomConstraint.constant = reactionsMenuViewBottomEndConstraintConstant
        }
        
        reactionsMenuView.alpha = 1
        reactionsMenuContainerView.transform = CGAffineTransform.identity
    }
    
    func hideReactionsMenu() {
        guard self.shouldPresentReactionsMenu, let reactionsMenuView = self.reactionsMenuView else {
            return
        }
        
        if let reactionsMenuViewBottomStartConstraintConstant = self.reactionsMenuViewBottomStartConstraintConstant {
            self.reactionsMenuViewBottomConstraint.constant = reactionsMenuViewBottomStartConstraintConstant
        }
        
        reactionsMenuView.alpha = 0
        
        let transformScale = Constants.reactionsMenuViewHiddenScale
        self.reactionsMenuContainerView.transform = CGAffineTransform(scaleX: transformScale, y: transformScale)
    }
    
    func selectedReactionAnimationsIntructionsPart1() {
        self.reactionsMenuView?.selectionAnimationInstructionPart1()
    }
    
    func selectedReactionAnimationsIntructionsPart2() {
        self.reactionsMenuView?.selectionAnimationInstructionPart2()
    }
    
    func update(theme: Theme) {
        self.menuToolbarView.update(theme: theme)
        self.reactionsMenuView?.update(theme: theme)
    }
    
    // MARK: - Private
    
    private func updateViews() {
        self.menuToolbarView.fill(contextualMenuItems: self.contextualMenuItems)
        
        let hideReactionMenu: Bool
        
        if let reactionsMenuViewModel = self.reactionsMenuViewModel {
            hideReactionMenu = false
            self.updateReactionsMenu(with: reactionsMenuViewModel)
        } else {
            hideReactionMenu = true
        }
        
        self.reactionsMenuContainerView.isHidden = hideReactionMenu
    }
    
    private func updateReactionsMenu(with viewModel: ReactionsMenuViewModel) {
        
        if self.reactionsMenuContainerView.subviews.isEmpty {
            let reactionsMenuView = ReactionsMenuView.loadFromNib()
            self.reactionsMenuContainerView.vc_addSubViewMatchingParent(reactionsMenuView)
            reactionsMenuView.update(theme: self.theme)
            self.reactionsMenuView = reactionsMenuView
        }
        
        self.reactionsMenuView?.viewModel = viewModel
    }
    
    private func setupBackgroundOverlayGestureRecognizers() {
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handle(gestureRecognizer:)))
        tapGestureRecognizer.delegate = self
        
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handle(gestureRecognizer:)))
        swipeGestureRecognizer.direction = [.down, .up]
        swipeGestureRecognizer.delegate = self
        
        self.backgroundOverlayView.addGestureRecognizer(tapGestureRecognizer)
        self.backgroundOverlayView.addGestureRecognizer(swipeGestureRecognizer)
    }
    
    @objc private func handle(gestureRecognizer: UIGestureRecognizer) {
        self.delegate?.roomContextualMenuViewControllerDidTapBackgroundOverlay(self)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension RoomContextualMenuViewController: UIGestureRecognizerDelegate {
    
    // Avoid triggering background overlay gesture recognizers when touching reactions menu
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.vc_isInside(view: self.reactionsMenuContainerView) == false
    }
}
