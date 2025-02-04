// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import Reusable

final class FileWithoutThumbnailCellContentView: UIView, NibLoadable {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var iconBackgroundView: UIView!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private(set) weak var titleLabel: UILabel!

    // MARK: Public
    
    var badgeImage: UIImage? {
        get {
            return self.iconImageView.image
        }
        set {
            self.iconImageView.image = newValue
        }
    }
    
    // MARK: - Setup
    
    static func instantiate() -> FileWithoutThumbnailCellContentView {
        return FileWithoutThumbnailCellContentView.loadFromNib()
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.masksToBounds = true
        self.iconImageView.image = Asset.Images.fileAttachment.image.withRenderingMode(.alwaysTemplate)
        self.iconBackgroundView.layer.masksToBounds = true
        
        update(theme: ThemeService.shared().theme)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = BubbleRoomCellLayoutConstants.bubbleCornerRadius
        self.iconBackgroundView.layer.cornerRadius = self.iconBackgroundView.bounds.midX
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.iconBackgroundView.backgroundColor = theme.roomCellIncomingBubbleBackgroundColor
        self.iconImageView.tintColor = theme.colors.secondaryContent
    }
}
