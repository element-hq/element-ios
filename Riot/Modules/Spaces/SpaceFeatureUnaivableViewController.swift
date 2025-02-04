// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

final class SpaceFeatureUnaivableViewController: UIViewController {

    // MARK: - Properties
    
    // MARK: Outlets
        
    @IBOutlet private weak var artworkImageView: UIImageView!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    
    // MARK: Private
 
    private var theme: Theme!
    
    // MARK: - Setup
    
    class func instantiate() -> SpaceFeatureUnaivableViewController {
        let viewController = StoryboardScene.SpaceFeatureUnaivableViewController.initialScene.instantiate()
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupViews()
                
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        self.title = VectorL10n.spaceFeatureUnavailableTitle
        
        self.subtitleLabel.text = VectorL10n.spaceFeatureUnavailableSubtitle
        self.informationLabel.text = VectorL10n.spaceFeatureUnavailableInformation
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.theme = theme
                
        self.view.backgroundColor = theme.backgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.subtitleLabel.textColor = theme.textPrimaryColor
        self.informationLabel.textColor = theme.textSecondaryColor
        
        // Artwork image view
        
        let artworkImage = ThemeService.shared().isCurrentThemeDark() ?   Asset.Images.featureUnavaibleArtworkDark.image : Asset.Images.featureUnavaibleArtwork.image
        
        self.artworkImageView.image = artworkImage
    }
    
    func fill(informationText: String, shareLink: URL) {
        self.subtitleLabel.text = informationText
    }
}
