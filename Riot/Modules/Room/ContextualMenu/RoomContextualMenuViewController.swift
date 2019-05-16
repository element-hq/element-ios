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
}

@objcMembers
final class RoomContextualMenuViewController: UIViewController, Themable {
        
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var backgroundOverlayView: UIView!
    @IBOutlet private weak var menuToolbarView: RoomContextualMenuToolbarView!
    
    @IBOutlet private weak var menuToolbarViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var menuToolbarViewBottomConstraint: NSLayoutConstraint!
    
    // MARK: Private
    
    private var theme: Theme!
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
        
        self.backgroundOverlayView.isUserInteractionEnabled = true
        self.menuToolbarView.fill(contextualMenuItems: self.contextualMenuItems)
        self.setupBackgroundOverlayTapGestureRecognizer()
        
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
    
    func update(theme: Theme) {
        self.menuToolbarView.update(theme: theme)
    }
    
    // MARK: - Private
    
    private func setupBackgroundOverlayTapGestureRecognizer() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(gestureRecognizer:)))
        self.backgroundOverlayView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc private func handleTap(gestureRecognizer: UIGestureRecognizer) {
        self.delegate?.roomContextualMenuViewControllerDidTapBackgroundOverlay(self)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
}
