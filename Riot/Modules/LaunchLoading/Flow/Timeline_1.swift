// Made With Flow.
//
// DO NOT MODIFY, your changes will be lost when this file is regenerated.
//
// swiftlint:disable all

import UIKit

public class Timeline_1: Timeline {
    public convenience init(view: ElementView, duration: TimeInterval, autoreverses: Bool = false, repeatCount: Float = 0) {
        let animationsByLayer = Timeline_1.animationsByLayer(view: view, duration: duration)
        self.init(view: view, animationsByLayer: animationsByLayer, sounds: [], duration: duration, autoreverses: autoreverses, repeatCount: repeatCount)
    }
    private static func animationsByLayer(view: ElementView, duration: TimeInterval) -> [CALayer: [CAKeyframeAnimation]] {
        // Keyframe Animations for element
        let position_x_element: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "position.x"
            keyframeAnimation.values = [66, 65.65]
            keyframeAnimation.keyTimes = [0, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let position_y_element: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "position.y"
            keyframeAnimation.values = [65, 65.5]
            keyframeAnimation.keyTimes = [0, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let transform_rotation_z_element: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "transform.rotation.z"
            keyframeAnimation.values = [0, 3.14159, 6.28319]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let bounds_size_width_element: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "bounds.size.width"
            keyframeAnimation.values = [120, 120, 201]
            keyframeAnimation.keyTimes = [0, 0.125, 1]
            keyframeAnimation.timingFunctions = [.linear, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let bounds_size_height_element: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "bounds.size.height"
            keyframeAnimation.values = [120, 120, 201]
            keyframeAnimation.keyTimes = [0, 0.125, 1]
            keyframeAnimation.timingFunctions = [.linear, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
         
        // Keyframe Animations for rectangle
        let position_x_rectangle: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "position.x"
            keyframeAnimation.values = [60, 60.2, 100.84]
            keyframeAnimation.keyTimes = [0, 0.125, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let position_y_rectangle: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "position.y"
            keyframeAnimation.values = [60, 60.2, 100.84]
            keyframeAnimation.keyTimes = [0, 0.125, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let bounds_size_width_rectangle: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "bounds.size.width"
            keyframeAnimation.values = [120.4, 120.4, 201.67]
            keyframeAnimation.keyTimes = [0, 0.125, 1]
            keyframeAnimation.timingFunctions = [.linear, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let bounds_size_height_rectangle: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "bounds.size.height"
            keyframeAnimation.values = [120.4, 120.4, 201.67]
            keyframeAnimation.keyTimes = [0, 0.125, 1]
            keyframeAnimation.timingFunctions = [.linear, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let path_rectangle: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "path"
            keyframeAnimation.values = [CGPathCreateWithSVGString("M0.003,0.003l120.4,0 0,120.4 -120.4,0 0,-120.4zM0.003,0.003")!, CGPathCreateWithSVGString("M0.003,0.003l120.4,0 0,120.4 -120.4,0 0,-120.4zM0.003,0.003")!, CGPathCreateWithSVGString("M0.005,0.005l201.67,0 0,201.67 -201.67,0 0,-201.67zM0.005,0.005")!]
            keyframeAnimation.keyTimes = [0, 0.125, 1]
            keyframeAnimation.timingFunctions = [.linear, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
         
        // Keyframe Animations for element_1
        let position_x_element_1: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "position.x"
            keyframeAnimation.values = [60, 60, 100.5]
            keyframeAnimation.keyTimes = [0, 0.125, 1]
            keyframeAnimation.timingFunctions = [.linear, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let position_y_element_1: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "position.y"
            keyframeAnimation.values = [60, 60, 100.5]
            keyframeAnimation.keyTimes = [0, 0.125, 1]
            keyframeAnimation.timingFunctions = [.linear, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
         
        // Organize CAKeyframeAnimations by CALayer
        var animationsByLayer = [CALayer: [CAKeyframeAnimation]]()
        animationsByLayer[view.rectangle.layer] = [position_x_rectangle, bounds_size_height_rectangle, bounds_size_width_rectangle, path_rectangle, position_y_rectangle]
        animationsByLayer[view.element_1.layer] = [position_x_element_1, position_y_element_1]
        animationsByLayer[view.element.layer] = [position_x_element, bounds_size_height_element, bounds_size_width_element, position_y_element, transform_rotation_z_element]

        return animationsByLayer
    }
}
