// Made With Flow.
//
// DO NOT MODIFY, your changes will be lost when this file is regenerated.
//

import UIKit
import FlowCommoniOS

@IBDesignable
public class ElementView: UIView {
    public struct Defaults {
        public static let size = CGSize(width: 130.16, height: 127.75)
        public static let backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.021)
    }

    public var icon: UIView!
    public var _10242x: UIView!
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
            createIcon()
            create_10242x()
            createPath()
            createPath1()
            createPath2()
            createPath3()
        }
    }

    private func createIcon() {
        icon = UIView(frame: CGRect(x: 65.21, y: 63.27, width: 120.77, height: 120.77))
        icon.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0)
        icon.layer.shadowOffset = CGSize(width: 0, height: 0)
        icon.layer.shadowColor = UIColor.clear.cgColor
        icon.layer.shadowOpacity = 1
        icon.layer.position = CGPoint(x: 65.21, y: 63.27)
        icon.layer.bounds = CGRect(x: 0, y: 0, width: 120.77, height: 120.77)
        icon.layer.masksToBounds = false
    }

    private func create_10242x() {
        _10242x = UIView(frame: CGRect(x: 60.39, y: 60.39, width: 120, height: 120))
        _10242x.backgroundColor = UIColor.clear
        _10242x.layer.shadowOffset = CGSize(width: 0, height: 0)
        _10242x.layer.shadowColor = UIColor.clear.cgColor
        _10242x.layer.shadowOpacity = 1
        _10242x.layer.position = CGPoint(x: 60.39, y: 60.39)
        _10242x.layer.bounds = CGRect(x: 0, y: 0, width: 120, height: 120)
        _10242x.layer.masksToBounds = false
    }

    private func createPath() {
        path = ShapeView(frame: CGRect(x: 70.81, y: 27.59, width: 55.2, height: 55.2))
        path.backgroundColor = UIColor.clear
        path.layer.shadowOffset = CGSize(width: 0, height: 0)
        path.layer.shadowColor = UIColor.clear.cgColor
        path.layer.shadowOpacity = 1
        path.layer.position = CGPoint(x: 70.81, y: 27.59)
        path.layer.bounds = CGRect(x: 0, y: 0, width: 55.2, height: 55.2)
        path.layer.masksToBounds = false
        path.shapeLayer.fillRule = CAShapeLayerFillRule.evenOdd
        path.shapeLayer.fillColor = UIColor(rgb: 0x8454EB).cgColor
        path.shapeLayer.lineDashPattern = []
        path.shapeLayer.lineDashPhase = 0
        path.shapeLayer.lineWidth = 0
        path.shapeLayer.path = CGPathCreateWithSVGString("M0,7.2c0,-3.976,3.224,-7.2,7.2,-7.2 26.51,0,48,21.49,48,48 0,3.976,-3.224,7.2,-7.2,7.2 -3.976,0,-7.2,-3.224,-7.2,-7.2 0,-18.557,-15.043,-33.6,-33.6,-33.6 -3.976,0,-7.2,-3.224,-7.2,-7.2zM0,7.2")!

    }

    private func createPath1() {
        path_1 = ShapeView(frame: CGRect(x: 49.2, y: 92.41, width: 55.2, height: 55.2))
        path_1.backgroundColor = UIColor.clear
        path_1.layer.shadowOffset = CGSize(width: 0, height: 0)
        path_1.layer.shadowColor = UIColor.clear.cgColor
        path_1.layer.shadowOpacity = 1
        path_1.layer.position = CGPoint(x: 49.2, y: 92.41)
        path_1.layer.bounds = CGRect(x: 0, y: 0, width: 55.2, height: 55.2)
        path_1.layer.masksToBounds = false
        path_1.shapeLayer.fillRule = CAShapeLayerFillRule.evenOdd
        path_1.shapeLayer.fillColor = UIColor(rgb: 0x8454EB).cgColor
        path_1.shapeLayer.lineDashPattern = []
        path_1.shapeLayer.lineDashPhase = 0
        path_1.shapeLayer.lineWidth = 0
        path_1.shapeLayer.path = CGPathCreateWithSVGString("M55.2,48c0,3.976,-3.224,7.2,-7.2,7.2 -26.51,0,-48,-21.49,-48,-48 0,-3.976,3.224,-7.2,7.2,-7.2 3.976,0,7.2,3.224,7.2,7.2 0,18.557,15.043,33.6,33.6,33.6 3.976,0,7.2,3.224,7.2,7.2zM55.2,48")!

    }

    private func createPath2() {
        path_2 = ShapeView(frame: CGRect(x: 27.59, y: 49.2, width: 55.2, height: 55.2))
        path_2.backgroundColor = UIColor.clear
        path_2.layer.shadowOffset = CGSize(width: 0, height: 0)
        path_2.layer.shadowColor = UIColor.clear.cgColor
        path_2.layer.shadowOpacity = 1
        path_2.layer.position = CGPoint(x: 27.59, y: 49.2)
        path_2.layer.bounds = CGRect(x: 0, y: 0, width: 55.2, height: 55.2)
        path_2.layer.masksToBounds = false
        path_2.shapeLayer.fillRule = CAShapeLayerFillRule.evenOdd
        path_2.shapeLayer.fillColor = UIColor(rgb: 0x8454EB).cgColor
        path_2.shapeLayer.lineDashPattern = []
        path_2.shapeLayer.lineDashPhase = 0
        path_2.shapeLayer.lineWidth = 0
        path_2.shapeLayer.path = CGPathCreateWithSVGString("M7.2,55.2c-3.976,0,-7.2,-3.224,-7.2,-7.2 0,-26.51,21.49,-48,48,-48 3.976,0,7.2,3.224,7.2,7.2 0,3.976,-3.224,7.2,-7.2,7.2 -18.557,0,-33.6,15.043,-33.6,33.6 0,3.976,-3.224,7.2,-7.2,7.2zM7.2,55.2")!

    }

    private func createPath3() {
        path_3 = ShapeView(frame: CGRect(x: 92.41, y: 70.81, width: 55.2, height: 55.2))
        path_3.backgroundColor = UIColor.clear
        path_3.layer.shadowOffset = CGSize(width: 0, height: 0)
        path_3.layer.shadowColor = UIColor.clear.cgColor
        path_3.layer.shadowOpacity = 1
        path_3.layer.position = CGPoint(x: 92.41, y: 70.81)
        path_3.layer.bounds = CGRect(x: 0, y: 0, width: 55.2, height: 55.2)
        path_3.layer.masksToBounds = false
        path_3.shapeLayer.fillRule = CAShapeLayerFillRule.evenOdd
        path_3.shapeLayer.fillColor = UIColor(rgb: 0x8454EB).cgColor
        path_3.shapeLayer.lineDashPattern = []
        path_3.shapeLayer.lineDashPhase = 0
        path_3.shapeLayer.lineWidth = 0
        path_3.shapeLayer.path = CGPathCreateWithSVGString("M48,0c3.976,0,7.2,3.224,7.2,7.2 0,26.51,-21.49,48,-48,48 -3.976,0,-7.2,-3.224,-7.2,-7.2 0,-3.976,3.224,-7.2,7.2,-7.2 18.557,0,33.6,-15.043,33.6,-33.6 0,-3.976,3.224,-7.2,7.2,-7.2zM48,0")!

    }

    private func addSubviews() {
        _10242x.addSubview(path)
        _10242x.addSubview(path_1)
        _10242x.addSubview(path_2)
        _10242x.addSubview(path_3)
        icon.addSubview(_10242x)
        addSubview(icon)
    }
}
