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

import Reusable
import UIKit

final class FileWithoutThumbnailCellContentView: UIView, NibLoadable {
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private var iconBackgroundView: UIView!
    @IBOutlet private var iconImageView: UIImageView!
    @IBOutlet private(set) var titleLabel: UILabel!

    // MARK: Public
    
    var badgeImage: UIImage? {
        get {
            iconImageView.image
        }
        set {
            iconImageView.image = newValue
        }
    }
    
    // MARK: - Setup
    
    static func instantiate() -> FileWithoutThumbnailCellContentView {
        FileWithoutThumbnailCellContentView.loadFromNib()
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.masksToBounds = true
        iconImageView.image = Asset.Images.fileAttachment.image.withRenderingMode(.alwaysTemplate)
        iconBackgroundView.layer.masksToBounds = true
        
        update(theme: ThemeService.shared().theme)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = BubbleRoomCellLayoutConstants.bubbleCornerRadius
        iconBackgroundView.layer.cornerRadius = iconBackgroundView.bounds.midX
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        iconBackgroundView.backgroundColor = theme.roomCellIncomingBubbleBackgroundColor
        iconImageView.tintColor = theme.colors.secondaryContent
    }
}
