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
    
    @IBOutlet private var scrollView: UIScrollView!
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var closeButton: UIButton!
    
    @IBOutlet private var creatorInfoTitleLabel: UILabel!
    @IBOutlet private var creatorAvatarImageView: MXKImageView!
    @IBOutlet private var creatorDisplayNameLabel: UILabel!
    @IBOutlet private var creatorUserIDLabel: UILabel!
    
    @IBOutlet private var informationLabel: UILabel!
    
    @IBOutlet private var continueButton: UIButton!
    
    // MARK: Private
    
    private var viewModel: WidgetPermissionViewModel! {
        didSet {
            updateViews()
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
        
        setupViews()
        updateViews()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        scrollView.flashScrollIndicators()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
                
        creatorAvatarImageView.layer.cornerRadius = creatorAvatarImageView.frame.size.width / 2
        continueButton.layer.cornerRadius = Constants.continueButtonCornerRadius
        closeButton.layer.cornerRadius = closeButton.frame.size.width / 2
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.headerBackgroundColor
        
        titleLabel.textColor = theme.textPrimaryColor
        
        closeButton.vc_setBackgroundColor(theme.headerTextSecondaryColor, for: .normal)
        
        creatorInfoTitleLabel.textColor = theme.textSecondaryColor
        creatorDisplayNameLabel.textColor = theme.textSecondaryColor
        creatorUserIDLabel.textColor = theme.textSecondaryColor
        
        informationLabel.textColor = theme.textSecondaryColor
        
        continueButton.vc_setBackgroundColor(theme.tintColor, for: .normal)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        closeButton.layer.masksToBounds = true
        
        setupCreatorAvatarImageView()
        
        titleLabel.text = VectorL10n.roomWidgetPermissionTitle
        creatorInfoTitleLabel.text = VectorL10n.roomWidgetPermissionCreatorInfoTitle
        informationLabel.text = ""
        
        setupContinueButton()
    }
    
    private func updateViews() {
        if let avatarImageView = creatorAvatarImageView {
            let defaultavatarImage = AvatarGenerator.generateAvatar(forMatrixItem: viewModel.creatorUserId, withDisplayName: viewModel.creatorDisplayName)
            avatarImageView.setImageURI(viewModel.creatorAvatarUrl, withType: nil, andImageOrientation: .up, previewImage: defaultavatarImage, mediaManager: viewModel.mediaManager)
        }
        
        if let creatorDisplayNameLabel = creatorDisplayNameLabel {
            if let creatorDisplayName = viewModel.creatorDisplayName {
                creatorDisplayNameLabel.text = creatorDisplayName
            } else {
                creatorDisplayNameLabel.isHidden = true
            }
        }
        
        if let creatorUserIDLabel = creatorUserIDLabel {
            creatorUserIDLabel.text = viewModel.creatorUserId
        }
        
        if let informationLabel = informationLabel {
            informationLabel.text = viewModel.permissionsInformationText
        }
    }
    
    private func setupCreatorAvatarImageView() {
        creatorAvatarImageView.defaultBackgroundColor = UIColor.clear
        creatorAvatarImageView.enableInMemoryCache = true
        creatorAvatarImageView.clipsToBounds = true
    }
    
    private func setupContinueButton() {
        continueButton.layer.masksToBounds = true
        continueButton.setTitle(VectorL10n.continue, for: .normal)
    }
    
    // MARK: - Actions
    
    @IBAction private func closeButtonAction(_ sender: Any) {
        didTapCloseButton?()
    }
    
    @IBAction private func continueButtonAction(_ sender: Any) {
        didTapContinueButton?()
    }
}

// MARK: - SlidingModalPresentable

extension WidgetPermissionViewController: SlidingModalPresentable {
    func allowsDismissOnBackgroundTap() -> Bool {
        false
    }
    
    func layoutHeightFittingWidth(_ width: CGFloat) -> CGFloat {
        let sizingViewContoller: WidgetPermissionViewController
        
        if let viewController = WidgetPermissionViewController.Sizing.viewController {
            viewController.viewModel = viewModel
            sizingViewContoller = viewController
        } else {
            sizingViewContoller = WidgetPermissionViewController.instantiate(with: viewModel)
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
