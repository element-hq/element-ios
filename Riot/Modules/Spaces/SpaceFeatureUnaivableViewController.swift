//
// Copyright 2021 New Vector Ltd
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

import UIKit

final class SpaceFeatureUnaivableViewController: UIViewController {
    // MARK: - Properties
    
    // MARK: Outlets
        
    @IBOutlet private var artworkImageView: UIImageView!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var informationLabel: UILabel!
    
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

        setupViews()
                
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        title = VectorL10n.spaceFeatureUnavailableTitle
        
        subtitleLabel.text = VectorL10n.spaceFeatureUnavailableSubtitle
        informationLabel.text = VectorL10n.spaceFeatureUnavailableInformation
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.theme = theme
                
        view.backgroundColor = theme.backgroundColor
        
        if let navigationBar = navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        subtitleLabel.textColor = theme.textPrimaryColor
        informationLabel.textColor = theme.textSecondaryColor
        
        // Artwork image view
        
        let artworkImage = ThemeService.shared().isCurrentThemeDark() ? Asset.Images.featureUnavaibleArtworkDark.image : Asset.Images.featureUnavaibleArtwork.image
        
        artworkImageView.image = artworkImage
    }
    
    func fill(informationText: String, shareLink: URL) {
        subtitleLabel.text = informationText
    }
}
