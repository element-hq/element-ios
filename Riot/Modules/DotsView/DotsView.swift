// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

@IBDesignable
@objcMembers
class DotsView: UIView {
    // MARK: - Public properties
    
    @IBInspectable var highlightedDotColor: UIColor = .darkGray
    
    @IBInspectable var dotColor: UIColor = .lightGray
    
    @IBInspectable var dotMaxWidth: CGFloat = 10 {
        didSet {
            self.sizeToFit()
        }
    }
    
    @IBInspectable var dotMinWidth: CGFloat = 8 {
        didSet {
            self.sizeToFit()
        }
    }
    
    @IBInspectable var numberOfDots: UInt = 3 {
        didSet {
            createDotViews()
        }
    }
    
    @IBInspectable var interSpaceMargin: CGFloat = 7 {
        didSet {
            self.sizeToFit()
        }
    }
    
    // MARK: - Private members
    
    private var dotLayers: Array<CALayer> = Array()
    private var highlightedDotIndex: UInt = 0 {
        didSet {
            updateDotViews()
        }
    }
    private let updateInterval: TimeInterval = 0.4
    private var lastUpdateDate: Date = Date()
    private var animating: Bool = false {
        didSet {
            let displayLink = CADisplayLink(target: self, selector: #selector(fireTimer))
            displayLink.add(to: .current, forMode: .default)
        }
    }

    // MARK: - Lifecycle
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        createDotViews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createDotViews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateDotViews()
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: dotMaxWidth + (CGFloat(numberOfDots) - 1) * (dotMinWidth + interSpaceMargin), height: dotMaxWidth)
    }
    
    override func didMoveToSuperview() {
        animating = superview != nil
    }
    
    // MARK: - Interface Builder
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        createDotViews()
    }
    
    // MARK: - Private methods
    
    private func createDotViews() {
        while dotLayers.count > numberOfDots {
            dotLayers.popLast()?.removeFromSuperlayer()
        }
        
        while dotLayers.count < numberOfDots {
            let dotLayer = CALayer()
            dotLayer.masksToBounds = true
            layer.addSublayer(dotLayer)
            dotLayers.append(dotLayer)
        }
        
        if highlightedDotIndex >= dotLayers.count {
            highlightedDotIndex = 0
            updateDotViews()
        }
    }
    
    private func updateDotViews() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(1)
        var x: CGFloat = 0
        for (index, dotLayer) in dotLayers.enumerated() {
            if index == highlightedDotIndex {
                dotLayer.frame = CGRect(x: x, y: (bounds.height - dotMaxWidth) / 2, width: dotMaxWidth, height: dotMaxWidth)
                dotLayer.backgroundColor = dotColor.cgColor
            } else {
                dotLayer.frame = CGRect(x: x, y: (bounds.height - dotMinWidth) / 2, width: dotMinWidth, height: dotMinWidth)
                dotLayer.backgroundColor = index == ((highlightedDotIndex + 1) % numberOfDots) ? highlightedDotColor.cgColor : dotColor.cgColor
            }
            dotLayer.cornerRadius = dotLayer.bounds.height / 2
            x = dotLayer.frame.maxX + interSpaceMargin
        }
        lastUpdateDate = Date()
        CATransaction.commit()
    }
    
    @objc private func fireTimer() {
        if Date().timeIntervalSince(lastUpdateDate) >= updateInterval {
            self.highlightedDotIndex = (self.highlightedDotIndex + 1) % self.numberOfDots
        }
    }
}
