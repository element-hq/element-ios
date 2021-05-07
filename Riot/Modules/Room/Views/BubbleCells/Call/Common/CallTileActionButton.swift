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

enum CallTileActionButtonStyle {
    case positive
    case negative
    case custom(bgColor: UIColor, tintColor: UIColor)
}

class CallTileActionButton: UIButton {
    
    // MARK: - Constants
    
    private enum Constants {
        static let cornerRadius: CGFloat = 8.0
        static let fontSize: CGFloat = 17.0
        static let contentEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        static let spaceBetweenImageAndTitle: CGFloat = 8
        static let imageSize: CGSize = CGSize(width: 16, height: 16)
    }
    
    private var theme: Theme = ThemeService.shared().theme {
        didSet {
            updateStyle()
        }
    }
    
    private var hasImage: Bool {
        return image(for: .normal) != nil
    }
    
    var style: CallTileActionButtonStyle = .positive {
        didSet {
            updateStyle()
        }
    }
    
    // MARK: Setup
    
    init() {
        super.init(frame: .zero)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        contentEdgeInsets = Constants.contentEdgeInsets
        layer.masksToBounds = true
        titleLabel?.font = UIFont.systemFont(ofSize: Constants.fontSize)
        layer.cornerRadius = Constants.cornerRadius
        setImage(image(for: .normal)?.vc_resized(with: Constants.imageSize)?.withRenderingMode(.alwaysTemplate), for: .normal)
        updateStyle()
    }
    
    private func updateStyle() {
        switch style {
        case .positive:
            vc_setBackgroundColor(theme.tintColor, for: .normal)
            tintColor = theme.baseTextPrimaryColor
        case .negative:
            vc_setBackgroundColor(theme.noticeColor, for: .normal)
            tintColor = theme.baseTextPrimaryColor
        case .custom(let bgColor, let tintColor):
            vc_setBackgroundColor(bgColor, for: .normal)
            self.tintColor = tintColor
        }
    }
    
    // MARK: - Overrides
    
    override func setImage(_ image: UIImage?, for state: UIControl.State) {
        super.setImage(image?.vc_resized(with: Constants.imageSize)?.withRenderingMode(.alwaysTemplate),
                       for: state)
    }
    
    override var intrinsicContentSize: CGSize {
        var result = super.intrinsicContentSize
        guard hasImage else {
            return result
        }
        result.width += Constants.spaceBetweenImageAndTitle
        return result
    }
    
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        var result = super.imageRect(forContentRect: contentRect)
        guard hasImage else {
            return result
        }
        result.origin.x -= Constants.spaceBetweenImageAndTitle/2
        return result
    }
    
    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        var result = super.titleRect(forContentRect: contentRect)
        guard hasImage else {
            return result
        }
        result.origin.x += Constants.spaceBetweenImageAndTitle/2
        return result
    }
    
}

extension CallTileActionButton: Themable {
    
    func update(theme: Theme) {
        self.theme = theme
    }
    
}
