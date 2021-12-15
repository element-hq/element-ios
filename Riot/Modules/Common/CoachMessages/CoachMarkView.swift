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
import Reusable

/// `CoachMarkView` is used to display an information bubble view with a given text.
@objcMembers
class CoachMarkView: UIView, NibLoadable, Themable {
    
    // MARK: Constants
    
    @objc enum MarkPosition: Int, RawRepresentable {
        case topLeft
        case zero
        
        public var origin: CGPoint {
            switch self {
            case .topLeft:
                return CGPoint(x: 16, y: 40)
            case .zero:
                return .zero
            }
        }
    }
    
    // MARK: Private
    
    @IBOutlet private weak var backgroundView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!

    private var text: String? {
        didSet {
            textLabel.text = text
        }
    }
    private var position: MarkPosition = .zero
    
    // MARK: Setup
    
    class func instantiate(text: String?, position: MarkPosition) -> Self {
        let view = Self.loadFromNib()
        view.text = text
        view.position = position
        return view
    }
        
    // MARK: UIView
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        setupView()
        if newSuperview != nil {
            update(theme: ThemeService.shared().theme)
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        guard let superview = superview else {
            return
        }
        
        let origin = position.origin
        let layoutGuide = superview.safeAreaLayoutGuide
        translatesAutoresizingMaskIntoConstraints = false
        leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor, constant: origin.x).isActive = true
        topAnchor.constraint(equalTo: layoutGuide.topAnchor, constant: origin.y).isActive = true
    }
    
    // MARK: Themable
    
    func update(theme: Theme) {
        textLabel.textColor = theme.colors.background
        textLabel.font = theme.fonts.bodySB
        backgroundView.tintColor = theme.colors.accent
    }

    // MARK: Private
    
    private func setupView() {
        let imageSize = Asset.Images.coachMark.image.size
        let center = CGPoint(x: ceil(imageSize.width / 2), y: ceil(imageSize.height / 2))
        backgroundView.image = Asset.Images.coachMark.image.resizableImage(withCapInsets: .init(top: center.y - 1, left: center.x - 1, bottom: center.y + 1, right: center.x + 1), resizingMode: .stretch)
        
        textLabel.text = text
    }
}
