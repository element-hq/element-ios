// File created from ScreenTemplate
// $ createScreen.sh SecretsSetupRecoveryKey SecretsSetupRecoveryKey
/*
 Copyright 2020 New Vector Ltd
 
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

@objc
final class MajorUpdateViewController: UIViewController {
    // MARK: - Constants
    
    private enum Sizing {
        static var viewController: MajorUpdateViewController?
        static var widthConstraint: NSLayoutConstraint?
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private var scrollView: UIScrollView!
    
    @IBOutlet private var oldLogoImageView: UIImageView!
    @IBOutlet private var disclosureImageView: UIImageView!
    @IBOutlet private var newLogoImageView: UIImageView!
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var informationLabel: UILabel!
    @IBOutlet private var learnMoreButton: RoundedButton!
    @IBOutlet private var doneButton: UIButton!
    
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
        
        setupViews()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide back button
        navigationItem.setHidesBackButton(true, animated: animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
                
        disclosureImageView.tintColor = theme.noticeSecondaryColor
                
        newLogoImageView.tintColor = theme.tintColor
                
        titleLabel.textColor = theme.textPrimaryColor
        informationLabel.textColor = theme.textSecondaryColor
        
        learnMoreButton.update(theme: theme)
        theme.applyStyle(onButton: doneButton)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        vc_removeBackTitle()
        
        oldLogoImageView.image = Asset.Images.oldLogo.image
        disclosureImageView.image = Asset.Images.disclosureIcon.image
        newLogoImageView.image = Asset.Images.launchScreenLogo.image
        
        titleLabel.text = VectorL10n.majorUpdateTitle(AppInfo.current.displayName)
        informationLabel.text = VectorL10n.majorUpdateInformation
        
        learnMoreButton.setTitle(VectorL10n.majorUpdateLearnMoreAction, for: .normal)
        doneButton.setTitle(VectorL10n.majorUpdateDoneAction, for: .normal)
    }
    
    // MARK: - Actions

    @IBAction private func learnMoreButtonAction(_ sender: Any) {
        didTapLearnMoreButton?()
    }
    
    @IBAction private func doneButtonAction(_ sender: Any) {
        didTapDoneButton?()
    }
}

// MARK: - SlidingModalPresentable

extension MajorUpdateViewController: SlidingModalPresentable {
    func allowsDismissOnBackgroundTap() -> Bool {
        true
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
