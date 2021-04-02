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

@IBDesignable
@objcMembers
class BadgeLabel: UILabel {

    // MARK: - Public properties
    
    @IBInspectable var badgeColor: UIColor = .red {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    @IBInspectable var borderColor: UIColor = .white {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    @IBInspectable var padding: CGSize = CGSize(width: 10, height: 3) {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    // MARK: - Lifecycle
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = self.bounds.size.height / 2
    }
    
    override var intrinsicContentSize: CGSize {
        var intrinsicSize = super.intrinsicContentSize
        intrinsicSize.height = max(intrinsicSize.height + padding.height, intrinsicSize.height) + borderWidth / 2
        intrinsicSize.width = max(intrinsicSize.width + padding.width, intrinsicSize.height)
        return intrinsicSize
    }
    
    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            context.saveGState()
            
            let rect = self.bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2)
            let cornerRadius = rect.height / 2
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            
            context.addPath(path.cgPath)
            context.setLineWidth(borderWidth)
            context.setStrokeColor(borderColor.cgColor)
            context.setFillColor(badgeColor.cgColor)
            
            if borderWidth > 0 {
                context.drawPath(using: .fillStroke)
            } else {
                context.drawPath(using: .fill)
            }
            
            context.restoreGState()
        }
        
        super.draw(rect)
    }
    
    // MARK: - Interface Builder
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }
    
    // MARK: - Private methods
    
    private func setupView() {
        self.textAlignment = .center
        self.textColor = .white
    }
}
