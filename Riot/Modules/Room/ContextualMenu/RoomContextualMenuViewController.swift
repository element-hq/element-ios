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

@objc protocol RoomContextualMenuViewControllerDelegate: class {
    func roomContextualMenuViewControllerDidTapBackgroundOverlay(_ viewController: RoomContextualMenuViewController)
    func roomContextualMenuViewControllerDidReaction(_ viewController: RoomContextualMenuViewController)
}

@objcMembers
final class RoomContextualMenuViewController: UIViewController, Themable {
        
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var backgroundOverlayView: UIView!
    @IBOutlet private weak var menuToolbarView: RoomContextualMenuToolbarView!
    
    @IBOutlet private weak var menuToolbarViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var menuToolbarViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var reactionsMenuView: ReactionsMenuView!
    @IBOutlet private weak var reactionsMenuViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var reactionsMenuViewBottomConstraint: NSLayoutConstraint!
    
    // MARK: Private
    
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var contextualMenuItems: [RoomContextualMenuItem] = []    
    
    private var hiddenToolbarViewBottomConstant: CGFloat {
        let bottomSafeAreaHeight: CGFloat
        
        if #available(iOS 11.0, *) {
            bottomSafeAreaHeight = self.view.safeAreaInsets.bottom
        } else {
            bottomSafeAreaHeight = self.bottomLayoutGuide.length
        }
        
        return -(self.menuToolbarViewHeightConstraint.constant + bottomSafeAreaHeight)
    }
    
    // MARK: Public
    
    weak var delegate: RoomContextualMenuViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(with contextualMenuItems: [RoomContextualMenuItem]) -> RoomContextualMenuViewController {
        let viewController = StoryboardScene.RoomContextualMenuViewController.initialScene.instantiate()
        viewController.theme = ThemeService.shared().theme
        viewController.contextualMenuItems = contextualMenuItems
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.reactionsMenuView.isHidden = true

        self.backgroundOverlayView.isUserInteractionEnabled = true
        self.menuToolbarView.fill(contextualMenuItems: self.contextualMenuItems)
        self.setupBackgroundOverlayGestureRecognizers()

        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
    }
    
    // MARK: - Public
    
    func showMenuToolbar() {
        self.menuToolbarViewBottomConstraint.constant = 0
    }
    
    func hideMenuToolbar() {
        self.menuToolbarViewBottomConstraint.constant = self.hiddenToolbarViewBottomConstant
    }

    func showReactionsMenu(withViewModel viewModel: ReactionsMenuViewModel, aroundFrame frame: CGRect) {
        self.reactionsMenuView.viewModel = viewModel
        self.reactionsMenuView.isHidden = false

        let menuHeight = self.reactionsMenuViewHeightConstraint.constant

        // Try to display the menu at the top of the message first
        // Then, try at the bottom
        // Else, keep the position defined in the storyboard
        if frame.origin.y >= self.reactionsMenuViewHeightConstraint.constant {
            self.reactionsMenuViewBottomConstraint.constant = frame.origin.y
        } else {
            let frameBottomY = frame.origin.y + frame.size.height
            let visibleViewHeight = self.view.frame.size.height - self.menuToolbarView.frame.size.height

            if frameBottomY + menuHeight < visibleViewHeight {
                self.reactionsMenuViewBottomConstraint.constant = frameBottomY + menuHeight
            }
        }
    }
    
    func update(theme: Theme) {
        self.menuToolbarView.update(theme: theme)
    }
    
    // MARK: - Private
    
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
        return touch.vc_isInside(view: self.reactionsMenuView) == false
    }
}
