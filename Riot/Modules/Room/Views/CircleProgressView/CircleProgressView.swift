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
class CircleProgressView: MXKPieChartView {
    // MARK: - Constants
    
    private static let minStrokeEnd: CGFloat = 0.000000000001
    private static let maxStrokeEnd: CGFloat = 1

    // MARK: - Public properties
    
    @IBInspectable var lineColor: UIColor = .lightGray {
        didSet {
            shapeLayer?.strokeColor = lineColor.cgColor
        }
    }
    @IBInspectable var lineWidth: CGFloat = 2 {
        didSet {
            shapeLayer?.lineWidth = lineWidth
        }
    }
    var value: CGFloat = 0 {
        didSet {
            stopAnimating()
            strokeEnd = max(min(value, CircleProgressView.maxStrokeEnd), CircleProgressView.minStrokeEnd)
        }
    }
    override var progress: CGFloat {
        get {
            return value
        }
        set {
            value = newValue
        }
    }

    // MARK: - Private members
    
    private weak var shapeLayer: CAShapeLayer?
    private var strokeEnd: CGFloat = minStrokeEnd {
        didSet {
            shapeLayer?.strokeEnd = strokeEnd
        }
    }
    private var startAngle: CGFloat = -.pi/2
    private(set) var isAnimating = false

    // MARK: - Lifecycle
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initLayer()
        initPath()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initLayer()
        initPath()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        shapeLayer?.frame = self.layer.bounds
        initPath()
    }
    
    // MARK: - Interface Builder
    
    override func prepareForInterfaceBuilder() {
        value = 0.8
    }
    
    // MARK: - Animation management
    
    func startAnimating() {
        guard !isAnimating else {
            return
        }
        
        isAnimating = true
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.fromValue = CGFloat.pi / 2
        rotationAnimation.toValue = CGFloat.pi * 2.5
        rotationAnimation.repeatCount = .infinity
        rotationAnimation.duration = 2
        shapeLayer?.add(rotationAnimation, forKey: "rotationAnimation")

        let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeAnimation.fromValue = 0
        strokeAnimation.toValue = 0.9
        strokeAnimation.repeatCount = .infinity
        strokeAnimation.duration = 0.9
        strokeAnimation.autoreverses = true
        strokeAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        shapeLayer?.add(strokeAnimation, forKey: "path")
    }
    
    func stopAnimating() {
        guard isAnimating else {
            return
        }
        
        shapeLayer?.removeAllAnimations()
        isAnimating = false
    }
    
    // MARK: - Private methods
    
    private func initLayer() {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = lineColor.cgColor
        layer.lineCap = .round
        layer.lineWidth = lineWidth
        layer.allowsEdgeAntialiasing = true
        layer.strokeEnd = strokeEnd

        self.layer.insertSublayer(layer, at: 0)
        shapeLayer = layer
    }
    
    private func initPath() {
        let endAngle: CGFloat = startAngle + .pi * 2
        let path = UIBezierPath(arcCenter: CGPoint(x: self.bounds.midX, y: self.bounds.midY), radius: (self.bounds.width - lineWidth) / 2, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        shapeLayer?.path = path.cgPath
    }
}
