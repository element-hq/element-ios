// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

@objcMembers
class BadgedBarButtonItem: UIBarButtonItem {
    
    var baseButton: UIButton
    private var badgeLabel: UILabel
    
    private var theme: Theme
    
    var badgeText: String? {
        didSet {
            updateBadgeLabel()
        }
    }
    var badgeBackgroundColor: UIColor {
        didSet {
            updateBadgeLabel()
        }
    }
    var badgeTextColor: UIColor {
        didSet {
            updateBadgeLabel()
        }
    }
    var badgeFont: UIFont {
        didSet {
            updateBadgeLabel()
        }
    }
    var badgePadding: UIOffset {
        didSet {
            updateBadgeLabel()
        }
    }
    
    private var shouldHideBadge: Bool {
        guard let text = badgeText else {
            return true
        }
        return text.isEmpty || text == "0" || text == "nil" || text == "null"
    }
    
    init(withBaseButton baseButton: UIButton, theme: Theme) {
        self.baseButton = baseButton
        self.theme = theme
        badgeBackgroundColor = .gray
        badgeTextColor = .white
        badgeFont = .systemFont(ofSize: 12, weight: .semibold)
        badgePadding = UIOffset(horizontal: 8, vertical: 2)
        badgeLabel = UILabel(frame: .zero)
        badgeLabel.textAlignment = .center
        badgeLabel.clipsToBounds = true
        baseButton.addSubview(badgeLabel)
        super.init()
        customView = baseButton
        update(theme: theme)
        updateBadgeLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateBadgeLabel() {
        badgeLabel.isHidden = shouldHideBadge
        badgeLabel.backgroundColor = badgeBackgroundColor
        badgeLabel.font = badgeFont
        badgeLabel.textColor = badgeTextColor
        
        let labelSize = calculateLabelSize()
        var width = labelSize.width + badgePadding.horizontal
        let height = labelSize.height + badgePadding.vertical
        if width < height {
            //  let width at least be as height
            width = height
        }
        baseButton.sizeToFit()
        badgeLabel.frame = CGRect(x: baseButton.frame.width - baseButton.contentEdgeInsets.right - width/2,
                                  y: baseButton.contentEdgeInsets.top - height/2,
                                  width: width,
                                  height: height)
        badgeLabel.text = badgeText
        badgeLabel.layer.cornerRadius = badgeLabel.frame.height/2
    }
    
    private func calculateLabelSize() -> CGSize {
        let tmpLabel = UILabel(frame: badgeLabel.frame)
        tmpLabel.font = badgeFont
        tmpLabel.text = badgeText
        tmpLabel.sizeToFit()
        return tmpLabel.frame.size
    }
    
}

extension BadgedBarButtonItem: Themable {
    
    func update(theme: Theme) {
        self.theme = theme
        
        tintColor = theme.colors.accent
        baseButton.tintColor = theme.colors.accent
    }
    
}
