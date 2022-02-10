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
    
    public static var TopLeftPosition: CGPoint {
        if UIDevice.current.orientation.isPortrait {
            return CGPoint(x: 16, y: 40)
        } else {
            return CGPoint(x: 16, y: 32)
        }
    }
    
    enum MarkPosition: Int {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
    
    // MARK: Private
    
    @IBOutlet private weak var backgroundView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var textLabelTopMargin: NSLayoutConstraint!
    @IBOutlet private weak var textLabelBottomMargin: NSLayoutConstraint!

    private var text: String? {
        didSet {
            textLabel.text = text
        }
    }
    private var markPosition: MarkPosition = .topLeft
    private var position: CGPoint!
    
    // MARK: Setup
    
    class func instantiate(text: String?, from position: CGPoint, markPosition: MarkPosition) -> Self {
        let view = Self.loadFromNib()
        view.text = text
        view.position = position
        view.markPosition = markPosition
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
        
        let layoutGuide = superview.safeAreaLayoutGuide
        translatesAutoresizingMaskIntoConstraints = false
        leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor, constant: position.x).isActive = true
        topAnchor.constraint(equalTo: layoutGuide.topAnchor, constant: position.y).isActive = true
    }
    
    // MARK: Themable
    
    func update(theme: Theme) {
        textLabel.textColor = theme.colors.background
        textLabel.font = theme.fonts.bodySB
        backgroundView.tintColor = theme.colors.accent
    }

    // MARK: Private
    
    private func setupView() {
        let image: UIImage = Asset.Images.coachMark.image
        let imageSize = image.size
        let center = CGPoint(x: ceil(imageSize.width / 2), y: ceil(imageSize.height / 2))
        
        backgroundView.image = image.resizableImage(withCapInsets: .init(top: center.y - 1, left: center.x - 1, bottom: center.y + 1, right: center.x + 1), resizingMode: .stretch)
        
        switch markPosition {
        case .topLeft:
            backgroundView.transform = .identity
        case .topRight:
            backgroundView.transform = .init(scaleX: -1, y: 1)
        case .bottomLeft:
            backgroundView.transform = .init(scaleX: 1, y: -1)
            invertVerticalMargins()
        case .bottomRight:
            backgroundView.transform = .init(scaleX: -1, y: -1)
            invertVerticalMargins()
        }
        
        textLabel.text = text
    }
    
    private func invertVerticalMargins() {
        let temp = self.textLabelTopMargin.constant
        self.textLabelTopMargin.constant = self.textLabelBottomMargin.constant
        self.textLabelBottomMargin.constant = temp
    }
}
