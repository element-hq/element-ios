// Made With Flow.
//
// DO NOT MODIFY, your changes will be lost when this file is regenerated.
//

import UIKit

@IBDesignable
public class ElementView: UIView {
    public struct Defaults {
        public static let size = CGSize(width: 130.22, height: 130.02)
        public static let backgroundColor = UIColor(displayP3Red: 0.052, green: 0.743, blue: 0.543, alpha: 0)
    }

    public var element: UIView!
    public var rectangle: ShapeView!
    public var element_1: UIView!
    public var path: ShapeView!
    public var path_1: ShapeView!
    public var path_2: ShapeView!
    public var path_3: ShapeView!

    public override var intrinsicContentSize: CGSize {
        return Defaults.size
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = Defaults.backgroundColor
        clipsToBounds = false
        createViews()
        addSubviews()
        //scale(to: frame.size)
    }

    /// Scales `self` and its subviews to `size`.
    ///
    /// - Parameter size: The size `self` is scaled to.
    ///
    /// UIKit specifies: "In iOS 8.0 and later, the transform property does not affect Auto Layout. Auto layout
    /// calculates a view's alignment rectangle based on its untransformed frame."
    ///
    /// see: https://developer.apple.com/documentation/uikit/uiview/1622459-transform
    ///
    /// If there are any constraints in IB affecting the frame of `self`, this method will have consequences on
    /// layout / rendering. To properly scale an animation, you will have to position the view manually.
    public func scale(to size: CGSize) {
        let x = size.width / Defaults.size.width
        let y = size.height / Defaults.size.height
        transform = CGAffineTransform(scaleX: x, y: y)
    }

    private func createViews() {
        CATransaction.suppressAnimations {
            createElement()
            createRectangle()
            createElement1()
            createPath()
            createPath1()
            createPath2()
            createPath3()
        }
    }

    private func createElement() {
        element = UIView(frame: CGRect(x: 66, y: 65, width: 120, height: 120))
        element.backgroundColor = UIColor.clear
        element.layer.shadowOffset = CGSize(width: 0, height: 0)
        element.layer.shadowColor = UIColor.clear.cgColor
        element.layer.shadowOpacity = 1
        element.layer.position = CGPoint(x: 66, y: 65)
        element.layer.bounds = CGRect(x: 0, y: 0, width: 120, height: 120)
        element.layer.masksToBounds = false
    }

    private func createRectangle() {
        rectangle = ShapeView(frame: CGRect(x: 60, y: 60, width: 120.4, height: 120.4))
        rectangle.backgroundColor = UIColor.clear
        rectangle.alpha = 0
        rectangle.layer.shadowOffset = CGSize(width: 0, height: 0)
        rectangle.layer.shadowColor = UIColor.clear.cgColor
        rectangle.layer.shadowOpacity = 1
        rectangle.layer.position = CGPoint(x: 60, y: 60)
        rectangle.layer.bounds = CGRect(x: 0, y: 0, width: 120.4, height: 120.4)
        rectangle.layer.masksToBounds = false
        rectangle.shapeLayer.fillRule = CAShapeLayerFillRule.evenOdd
        rectangle.shapeLayer.fillColor = nil
        rectangle.shapeLayer.lineDashPattern = []
        rectangle.shapeLayer.lineDashPhase = 0
        rectangle.shapeLayer.lineWidth = 0
        rectangle.shapeLayer.path = CGPathCreateWithSVGString("M0.003,0.003l120.4,0 0,120.4 -120.4,0 0,-120.4zM0.003,0.003")!

    }

    private func createElement1() {
        element_1 = UIView(frame: CGRect(x: 60, y: 60, width: 120, height: 120))
        element_1.backgroundColor = UIColor.clear
        element_1.layer.shadowOffset = CGSize(width: 0, height: 0)
        element_1.layer.shadowColor = UIColor.clear.cgColor
        element_1.layer.shadowOpacity = 1
        element_1.layer.position = CGPoint(x: 60, y: 60)
        element_1.layer.bounds = CGRect(x: 0, y: 0, width: 120, height: 120)
        element_1.layer.masksToBounds = false
    }

    private func createPath() {
        path = ShapeView(frame: CGRect(x: 70.8, y: 27.6, width: 55.2, height: 55.2))
        path.backgroundColor = UIColor.clear
        path.layer.shadowOffset = CGSize(width: 0, height: 0)
        path.layer.shadowColor = UIColor.clear.cgColor
        path.layer.shadowOpacity = 1
        path.layer.position = CGPoint(x: 70.8, y: 27.6)
        path.layer.bounds = CGRect(x: 0, y: 0, width: 55.2, height: 55.2)
        path.layer.masksToBounds = false
        path.shapeLayer.fillRule = CAShapeLayerFillRule.evenOdd
        path.shapeLayer.fillColor = UIColor(displayP3Red: 0.052, green: 0.743, blue: 0.543, alpha: 1).cgColor
        path.shapeLayer.lineDashPattern = []
        path.shapeLayer.lineDashPhase = 0
        path.shapeLayer.lineWidth = 0
        path.shapeLayer.path = CGPathCreateWithSVGString("M0,7.2c0,-3.976,3.224,-7.2,7.2,-7.2 26.51,0,48,21.49,48,48 0,3.976,-3.224,7.2,-7.2,7.2 -3.976,0,-7.2,-3.224,-7.2,-7.2 0,-18.557,-15.043,-33.6,-33.6,-33.6 -3.976,0,-7.2,-3.224,-7.2,-7.2zM0,7.2")!

    }

    private func createPath1() {
        path_1 = ShapeView(frame: CGRect(x: 49.2, y: 92.4, width: 55.2, height: 55.2))
        path_1.backgroundColor = UIColor.clear
        path_1.layer.shadowOffset = CGSize(width: 0, height: 0)
        path_1.layer.shadowColor = UIColor.clear.cgColor
        path_1.layer.shadowOpacity = 1
        path_1.layer.position = CGPoint(x: 49.2, y: 92.4)
        path_1.layer.bounds = CGRect(x: 0, y: 0, width: 55.2, height: 55.2)
        path_1.layer.masksToBounds = false
        path_1.shapeLayer.fillRule = CAShapeLayerFillRule.evenOdd
        path_1.shapeLayer.fillColor = UIColor(displayP3Red: 0.052, green: 0.743, blue: 0.543, alpha: 1).cgColor
        path_1.shapeLayer.lineDashPattern = []
        path_1.shapeLayer.lineDashPhase = 0
        path_1.shapeLayer.lineWidth = 0
        path_1.shapeLayer.path = CGPathCreateWithSVGString("M55.2,48c0,3.976,-3.224,7.2,-7.2,7.2 -26.51,0,-48,-21.49,-48,-48 0,-3.976,3.224,-7.2,7.2,-7.2 3.976,0,7.2,3.224,7.2,7.2 0,18.557,15.043,33.6,33.6,33.6 3.976,0,7.2,3.224,7.2,7.2zM55.2,48")!

    }

    private func createPath2() {
        path_2 = ShapeView(frame: CGRect(x: 27.6, y: 49.2, width: 55.2, height: 55.2))
        path_2.backgroundColor = UIColor.clear
        path_2.layer.shadowOffset = CGSize(width: 0, height: 0)
        path_2.layer.shadowColor = UIColor.clear.cgColor
        path_2.layer.shadowOpacity = 1
        path_2.layer.position = CGPoint(x: 27.6, y: 49.2)
        path_2.layer.bounds = CGRect(x: 0, y: 0, width: 55.2, height: 55.2)
        path_2.layer.masksToBounds = false
        path_2.shapeLayer.fillRule = CAShapeLayerFillRule.evenOdd
        path_2.shapeLayer.fillColor = UIColor(displayP3Red: 0.052, green: 0.743, blue: 0.543, alpha: 1).cgColor
        path_2.shapeLayer.lineDashPattern = []
        path_2.shapeLayer.lineDashPhase = 0
        path_2.shapeLayer.lineWidth = 0
        path_2.shapeLayer.path = CGPathCreateWithSVGString("M7.2,55.2c-3.976,0,-7.2,-3.224,-7.2,-7.2 0,-26.51,21.49,-48,48,-48 3.976,0,7.2,3.224,7.2,7.2 0,3.976,-3.224,7.2,-7.2,7.2 -18.557,0,-33.6,15.043,-33.6,33.6 0,3.976,-3.224,7.2,-7.2,7.2zM7.2,55.2")!

    }

    private func createPath3() {
        path_3 = ShapeView(frame: CGRect(x: 92.4, y: 70.8, width: 55.2, height: 55.2))
        path_3.backgroundColor = UIColor.clear
        path_3.layer.shadowOffset = CGSize(width: 0, height: 0)
        path_3.layer.shadowColor = UIColor.clear.cgColor
        path_3.layer.shadowOpacity = 1
        path_3.layer.position = CGPoint(x: 92.4, y: 70.8)
        path_3.layer.bounds = CGRect(x: 0, y: 0, width: 55.2, height: 55.2)
        path_3.layer.masksToBounds = false
        path_3.shapeLayer.fillRule = CAShapeLayerFillRule.evenOdd
        path_3.shapeLayer.fillColor = UIColor(displayP3Red: 0.052, green: 0.743, blue: 0.543, alpha: 1).cgColor
        path_3.shapeLayer.lineDashPattern = []
        path_3.shapeLayer.lineDashPhase = 0
        path_3.shapeLayer.lineWidth = 0
        path_3.shapeLayer.path = CGPathCreateWithSVGString("M48,0c3.976,0,7.2,3.224,7.2,7.2 0,26.51,-21.49,48,-48,48 -3.976,0,-7.2,-3.224,-7.2,-7.2 0,-3.976,3.224,-7.2,7.2,-7.2 18.557,0,33.6,-15.043,33.6,-33.6 0,-3.976,3.224,-7.2,7.2,-7.2zM48,0")!

    }

    private func addSubviews() {
        element_1.addSubview(path)
        element_1.addSubview(path_1)
        element_1.addSubview(path_2)
        element_1.addSubview(path_3)
        element.addSubview(rectangle)
        element.addSubview(element_1)
        addSubview(element)
    }
}
