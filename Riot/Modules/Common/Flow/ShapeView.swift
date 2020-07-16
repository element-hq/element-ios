// Copyright © 2016-2019 JABT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions: The above copyright
// notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

import UIKit

open class ShapeView: UIView {
    open var shapeLayer: CAShapeLayer {
        return (layer as? CAShapeLayer)!
    }

    /// A sublayer which can be used to apply a gradient fill to `self`.
    open var gradientLayer: CAGradientLayer? {
        set {
            // Remove old gradient layer
            if let gradientLayer = gradientLayer {
                gradientLayer.removeFromSuperlayer()
            }
            // Replace old gradient with new one
            if let newGradientLayer = newValue {
                layer.addSublayer(newGradientLayer)
            }
        }

        get {
            return layer.sublayers?.first(where: { $0 is CAGradientLayer }) as? CAGradientLayer
        }
    }

    public func addGradient(type: CAGradientLayerType, startPoint: CGPoint, endPoint: CGPoint, stops: [(color: CGColor, location: NSNumber)]) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = shapeLayer.bounds
        self.gradientLayer = gradientLayer


        let mask = CAShapeLayer()
        mask.path = shapeLayer.path
        mask.fillColor = UIColor.black.cgColor
        mask.strokeColor = nil

        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.colors = stops.map { $0.color }
        gradientLayer.locations = stops.map { $0.location }
        gradientLayer.type = type
        gradientLayer.frame = shapeLayer.bounds
        gradientLayer.mask = mask
    }

    open var path: CGPath? {
        get {
            return shapeLayer.path
        }
        set {
            shapeLayer.path = newValue
        }
    }

    override open class var layerClass: AnyClass {
        return CAShapeLayer.self
    }
}
