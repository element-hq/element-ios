//
// Copyright 2020 New Vector Ltd
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

import Foundation
import Reusable

/// `RootTabEmptyViewDisplayMode` defines the way image and text should be displayed
enum RootTabEmptyViewDisplayMode {
    /// Default display: fitted for big images
    case `default`
    /// The image is shrinked to fit icon size and is rendered as templated.
    case icon
}

/// `RootTabEmptyView` is a view to display when there is no UI item to display on a screen.
@objcMembers
final class RootTabEmptyView: UIView, NibLoadable {
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private var iconBackgroundView: UIView!
    @IBOutlet private var iconView: UIImageView!
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var informationLabel: UILabel!
    @IBOutlet private(set) var contentView: UIView!

    // MARK: Private
    
    private var theme: Theme!
    
    // MARK: Public
    
    // MARK: - Setup
    
    class func instantiate() -> RootTabEmptyView {
        let view = RootTabEmptyView.loadFromNib()
        view.theme = ThemeService.shared().theme
        return view
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        informationLabel.text = VectorL10n.homeEmptyViewInformation
        
        iconBackgroundView.layer.masksToBounds = true
        iconBackgroundView.layer.cornerRadius = iconBackgroundView.bounds.width / 2
        iconBackgroundView.isHidden = true
    }
    
    // MARK: - Public
    
    func fill(with image: UIImage, title: String, informationText: String) {
        fill(with: image, title: title, informationText: informationText, displayMode: .default)
    }
    
    func fill(with image: UIImage, title: String, informationText: String, displayMode: RootTabEmptyViewDisplayMode) {
        imageView.image = image
        iconView.image = image.withRenderingMode(.alwaysTemplate)
        titleLabel.text = title
        informationLabel.text = informationText
        imageView.isHidden = displayMode != .default
        iconBackgroundView.isHidden = displayMode != .icon
    }
}

// MARK: - Themable

extension RootTabEmptyView: Themable {
    func update(theme: Theme) {
        self.theme = theme
        
        backgroundColor = theme.backgroundColor
        
        titleLabel.textColor = theme.textPrimaryColor
        informationLabel.textColor = theme.textSecondaryColor
        iconBackgroundView.backgroundColor = theme.colors.quinaryContent
        iconView.tintColor = theme.textSecondaryColor
    }
}
