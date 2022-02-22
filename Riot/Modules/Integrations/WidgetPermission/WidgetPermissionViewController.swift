// File created from ScreenTemplate
// $ createScreen.sh Modal/Show ServiceTermsModalScreen
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

@objc
final class WidgetPermissionViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let continueButtonCornerRadius: CGFloat = 8.0
    }
    
    private enum Sizing {
        static var viewController: WidgetPermissionViewController?
        static var widthConstraint: NSLayoutConstraint?
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var closeButton: UIButton!
    
    @IBOutlet private weak var creatorInfoTitleLabel: UILabel!
    @IBOutlet private weak var creatorAvatarImageView: MXKImageView!
    @IBOutlet private weak var creatorDisplayNameLabel: UILabel!
    @IBOutlet private weak var creatorUserIDLabel: UILabel!
    
    @IBOutlet private weak var informationLabel: UILabel!
    
    @IBOutlet private weak var continueButton: UIButton!
    
    // MARK: Private
    
    private var viewModel: WidgetPermissionViewModel! {
        didSet {
            self.updateViews()
        }
    }
    private var theme: Theme!
    
    // MARK: Public
    
    @objc var didTapCloseButton: (() -> Void)?
    @objc var didTapContinueButton: (() -> Void)?
    
    // MARK: - Setup
    
    @objc class func instantiate(with viewModel: WidgetPermissionViewModel) -> WidgetPermissionViewController {
        let viewController = StoryboardScene.WidgetPermissionViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.setupViews()
        self.updateViews()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.scrollView.flashScrollIndicators()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
                
        self.creatorAvatarImageView.layer.cornerRadius = self.creatorAvatarImageView.frame.size.width/2
        self.continueButton.layer.cornerRadius = Constants.continueButtonCornerRadius
        self.closeButton.layer.cornerRadius = self.closeButton.frame.size.width/2
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        self.titleLabel.textColor = theme.textPrimaryColor
        
        self.closeButton.vc_setBackgroundColor(theme.headerTextSecondaryColor, for: .normal)
        
        self.creatorInfoTitleLabel.textColor = theme.textSecondaryColor
        self.creatorDisplayNameLabel.textColor = theme.textSecondaryColor
        self.creatorUserIDLabel.textColor = theme.textSecondaryColor
        
        self.informationLabel.textColor = theme.textSecondaryColor
        
        self.continueButton.vc_setBackgroundColor(theme.tintColor, for: .normal)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        self.closeButton.layer.masksToBounds = true
        
        self.setupCreatorAvatarImageView()
        
        self.titleLabel.text = VectorL10n.roomWidgetPermissionTitle
        self.creatorInfoTitleLabel.text = VectorL10n.roomWidgetPermissionCreatorInfoTitle
        self.informationLabel.text = ""
        
        self.setupContinueButton()
    }
    
    private func updateViews() {
        
        if let avatarImageView = self.creatorAvatarImageView {
            let defaultavatarImage = AvatarGenerator.generateAvatar(forMatrixItem: self.viewModel.creatorUserId, withDisplayName: self.viewModel.creatorDisplayName)
            avatarImageView.setImageURI(self.viewModel.creatorAvatarUrl, withType: nil, andImageOrientation: .up, previewImage: defaultavatarImage, mediaManager: self.viewModel.mediaManager)
        }
        
        if let creatorDisplayNameLabel = self.creatorDisplayNameLabel {
            if let creatorDisplayName = self.viewModel.creatorDisplayName {
                creatorDisplayNameLabel.text = creatorDisplayName
            } else {
                creatorDisplayNameLabel.isHidden = true
            }
        }
        
        if let creatorUserIDLabel = self.creatorUserIDLabel {
            creatorUserIDLabel.text = self.viewModel.creatorUserId
        }
        
        if let informationLabel = self.informationLabel {
            informationLabel.text = self.viewModel.permissionsInformationText
        }
    }
    
    private func setupCreatorAvatarImageView() {
        self.creatorAvatarImageView.defaultBackgroundColor = UIColor.clear
        self.creatorAvatarImageView.enableInMemoryCache = true
        self.creatorAvatarImageView.clipsToBounds = true
    }
    
    private func setupContinueButton() {
        self.continueButton.layer.masksToBounds = true
        self.continueButton.setTitle(VectorL10n.continue, for: .normal)
    }
    
    // MARK: - Actions
    
    @IBAction private func closeButtonAction(_ sender: Any) {
        self.didTapCloseButton?()
    }
    
    @IBAction private func continueButtonAction(_ sender: Any) {
        self.didTapContinueButton?()
    }
}

// MARK: - SlidingModalPresentable
extension WidgetPermissionViewController: SlidingModalPresentable {
    
    func allowsDismissOnBackgroundTap() -> Bool {
        return false
    }
    
    func layoutHeightFittingWidth(_ width: CGFloat) -> CGFloat {
        
        let sizingViewContoller: WidgetPermissionViewController
        
        if let viewController = WidgetPermissionViewController.Sizing.viewController {
            viewController.viewModel = self.viewModel
            sizingViewContoller = viewController
        } else {
            sizingViewContoller = WidgetPermissionViewController.instantiate(with: self.viewModel)
            WidgetPermissionViewController.Sizing.viewController = sizingViewContoller
        }
        
        let sizingViewContollerView: UIView = sizingViewContoller.view
        
        if let widthConstraint = WidgetPermissionViewController.Sizing.widthConstraint {
            widthConstraint.constant = width
        } else {
            let widthConstraint = sizingViewContollerView.widthAnchor.constraint(equalToConstant: width)
            widthConstraint.isActive = true
            WidgetPermissionViewController.Sizing.widthConstraint = widthConstraint
        }
        
        sizingViewContollerView.layoutIfNeeded()
        
        return sizingViewContoller.scrollView.contentSize.height
    }
}
