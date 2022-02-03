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
