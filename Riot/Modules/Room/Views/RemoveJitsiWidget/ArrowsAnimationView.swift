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

import Foundation

class ArrowsAnimationView: UIView {
    
    private enum Constants {
        static let numberOfArrows: Int = 3
        static let arrowSize: CGSize = CGSize(width: 14, height: 14)
        static let gradientAnimationKey: String = "gradient"
        static let gradientRatios: [CGFloat] = [1.0, 0.3, 0.2]
    }
    
    private var gradientLayer: CAGradientLayer!
    private lazy var gradientAnimation: CABasicAnimation = {
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [0.0, 0.0, 0.25]
        animation.toValue = [0.75, 1.0, 1.0]
        animation.repeatCount = .infinity
        animation.duration = 1
        return animation
    }()
    private var theme: Theme = ThemeService.shared().theme
    private var arrowImageViews: [UIImageView] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        let arrowImage = Asset.Images.disclosureIcon.image
        for i in 0..<Constants.numberOfArrows {
            let totalSpace = frame.width - CGFloat(Constants.numberOfArrows) * Constants.arrowSize.width
            let oneSpace = totalSpace / CGFloat(Constants.numberOfArrows - 1)
            let x = CGFloat(i) * (oneSpace + Constants.arrowSize.width)
            let y = (frame.height - Constants.arrowSize.height) / 2
            let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: x, y: y),
                                                      size: Constants.arrowSize))
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = theme.tabBarUnselectedItemTintColor
            imageView.image = arrowImage
            addSubview(imageView)
            
            arrowImageViews.append(imageView)
        }

        gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.locations = [0.25, 0.5, 0.75]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        //  this color doesn't have to come from the theme, it's only used as a mask
        let color = UIColor.black
        let colors = Constants.gradientRatios.map({ color.withAlphaComponent($0) })
        gradientLayer.colors = colors.map({ $0.cgColor })

        layer.mask = gradientLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        gradientLayer.frame = bounds
    }
    
    //  MARK: - API
    
    var isAnimating: Bool = false {
        didSet {
            if isAnimating {
                if gradientLayer.animation(forKey: Constants.gradientAnimationKey) == nil {
                    gradientLayer.add(gradientAnimation,
                                      forKey: Constants.gradientAnimationKey)
                }
            } else {
                if gradientLayer.animation(forKey: Constants.gradientAnimationKey) != nil {
                    gradientLayer.removeAnimation(forKey: Constants.gradientAnimationKey)
                }
            }
        }
    }
}

//  MARK: - Themable

extension ArrowsAnimationView: Themable {
    
    func update(theme: Theme) {
        self.theme = theme
        
        arrowImageViews.forEach({ $0.tintColor = theme.tabBarUnselectedItemTintColor })
    }
    
}
