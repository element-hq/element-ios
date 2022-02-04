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

import UIKit
import Reusable

@objc
protocol AddItemHeaderViewDelegate: AnyObject {
    func addItemHeaderView(_ headerView: AddItemHeaderView, didTapButton button: UIButton)
}

/// `AddItemHeaderView` is a generic view used as a header view for UITableView.
/// With this view we can add an extra action cell with icon and text as for SpaceMemberList and SpaceExploreRooms
@objcMembers
final class AddItemHeaderView: UIView, NibLoadable, Themable {
    
    // MARK: - Constants
    
    private enum Constants {
        static let buttonHighlightedAlpha: CGFloat = 0.2
    }
    
    // MARK: - Properties
    
    @IBOutlet private weak var button: UIButton!
    @IBOutlet private weak var iconBackgroundView: UIView!
    @IBOutlet private weak var iconView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!

    weak var delegate: AddItemHeaderViewDelegate?
    
    private var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    private var icon: UIImage? {
        didSet {
            iconView.image = icon
        }
    }
    
    // MARK: - Setup
    
    static func instantiate(title: String?, icon: UIImage?) -> AddItemHeaderView {
        let view = AddItemHeaderView.loadFromNib()
        view.icon = icon
        view.title = title
        view.update(theme: ThemeService.shared().theme)
        return view
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        iconBackgroundView.layer.masksToBounds = true
        iconBackgroundView.layer.cornerRadius = iconBackgroundView.bounds.width / 2
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        iconBackgroundView.layer.backgroundColor = theme.colors.quinaryContent.cgColor
        iconView.tintColor = theme.colors.secondaryContent
        titleLabel.textColor = theme.colors.primaryContent
        titleLabel.font = theme.fonts.headline
    }
    
    // MARK: - Action
    
    @objc private func buttonAction(_ sender: UIButton) {
        delegate?.addItemHeaderView(self, didTapButton: button)
    }
}
