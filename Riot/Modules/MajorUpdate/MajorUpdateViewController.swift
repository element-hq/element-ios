// File created from ScreenTemplate
// $ createScreen.sh SecretsSetupRecoveryKey SecretsSetupRecoveryKey
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import UIKit

@objc
final class MajorUpdateViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Sizing {
        static var viewController: MajorUpdateViewController?
        static var widthConstraint: NSLayoutConstraint?
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var oldLogoImageView: UIImageView!
    @IBOutlet private weak var disclosureImageView: UIImageView!
    @IBOutlet private weak var newLogoImageView: UIImageView!
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    @IBOutlet private weak var learnMoreButton: RoundedButton!
    @IBOutlet private weak var doneButton: UIButton!
    
    // MARK: Private
 
    private var theme: Theme!
    
    // MARK: Public
    
    @objc var didTapLearnMoreButton: (() -> Void)?
    @objc var didTapDoneButton: (() -> Void)?

    // MARK: - Setup
    
    @objc class func instantiate() -> MajorUpdateViewController {
        let viewController = StoryboardScene.MajorUpdateViewController.initialScene.instantiate()
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.setupViews()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide back button
        self.navigationItem.setHidesBackButton(true, animated: animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
                
        self.disclosureImageView.tintColor = theme.noticeSecondaryColor
                
        self.newLogoImageView.tintColor = theme.tintColor
                
        self.titleLabel.textColor = theme.textPrimaryColor
        self.informationLabel.textColor = theme.textSecondaryColor
        
        self.learnMoreButton.update(theme: theme)
        theme.applyStyle(onButton: self.doneButton)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        self.vc_removeBackTitle()
        
        self.oldLogoImageView.image = Asset.Images.oldLogo.image
        self.disclosureImageView.image = Asset.Images.disclosureIcon.image
        self.newLogoImageView.image = Asset.Images.launchScreenLogo.image
        
        self.titleLabel.text = VectorL10n.majorUpdateTitle(AppInfo.current.displayName)
        self.informationLabel.text = VectorL10n.majorUpdateInformation
        
        self.learnMoreButton.setTitle(VectorL10n.majorUpdateLearnMoreAction, for: .normal)
        self.doneButton.setTitle(VectorL10n.majorUpdateDoneAction, for: .normal)
    }
    
    // MARK: - Actions

    @IBAction private func learnMoreButtonAction(_ sender: Any) {
        self.didTapLearnMoreButton?()
    }
    
    @IBAction private func doneButtonAction(_ sender: Any) {
        self.didTapDoneButton?()
    }
}

// MARK: - SlidingModalPresentable
extension MajorUpdateViewController: SlidingModalPresentable {
    
    func allowsDismissOnBackgroundTap() -> Bool {
        return true
    }
    
    func layoutHeightFittingWidth(_ width: CGFloat) -> CGFloat {
        
        let sizingViewContoller: MajorUpdateViewController
        
        if let viewController = MajorUpdateViewController.Sizing.viewController {
            sizingViewContoller = viewController
        } else {
            sizingViewContoller = MajorUpdateViewController.instantiate()
            MajorUpdateViewController.Sizing.viewController = sizingViewContoller
        }
        
        let sizingViewContollerView: UIView = sizingViewContoller.view
        
        if let widthConstraint = MajorUpdateViewController.Sizing.widthConstraint {
            widthConstraint.constant = width
        } else {
            let widthConstraint = sizingViewContollerView.widthAnchor.constraint(equalToConstant: width)
            widthConstraint.isActive = true
            MajorUpdateViewController.Sizing.widthConstraint = widthConstraint
        }
        
        sizingViewContollerView.layoutIfNeeded()
        
        return sizingViewContoller.scrollView.contentSize.height
    }
}
