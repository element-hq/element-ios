// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
