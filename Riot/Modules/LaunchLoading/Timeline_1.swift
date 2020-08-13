// Made With Flow.
//
// DO NOT MODIFY, your changes will be lost when this file is regenerated.
//
// swiftlint:disable all

import UIKit
import FlowCommoniOS

public class Timeline_1: Timeline {
    public convenience init(view: ElementView, duration: TimeInterval, autoreverses: Bool = false, repeatCount: Float = 0) {
        let animationsByLayer = Timeline_1.animationsByLayer(view: view, duration: duration)
        self.init(view: view, animationsByLayer: animationsByLayer, sounds: [], duration: duration, autoreverses: autoreverses, repeatCount: repeatCount)
    }
    private static func animationsByLayer(view: ElementView, duration: TimeInterval) -> [CALayer: [CAKeyframeAnimation]] {
        // Keyframe Animations for icon
        let position_x_icon: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "position.x"
            keyframeAnimation.values = [65.21, 65.06, 65, 64.63]
            keyframeAnimation.keyTimes = [0, 0.5, 0.96, 1]
            keyframeAnimation.timingFunctions = [.easeIn, .easeOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let position_y_icon: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "position.y"
            keyframeAnimation.values = [63.27, 63.43, 63, 63.29]
            keyframeAnimation.keyTimes = [0, 0.5, 0.96, 1]
            keyframeAnimation.timingFunctions = [.easeIn, .easeOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let transform_rotation_z_icon: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "transform.rotation.z"
            keyframeAnimation.values = [0, 3.14159, 6.28319]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeIn, .easeOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let bounds_size_width_icon: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "bounds.size.width"
            keyframeAnimation.values = [120.77, 141.91, 120.77]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeIn, .easeOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let bounds_size_height_icon: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "bounds.size.height"
            keyframeAnimation.values = [120.77, 141.91, 120.77]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeIn, .easeOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let backgroundcolor_icon: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "backgroundColor"
            keyframeAnimation.values = [UIColor(red: 1, green: 1, blue: 1, alpha: 0).cgColor, UIColor.clear.cgColor]
            keyframeAnimation.keyTimes = [0, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
         
        // Keyframe Animations for _10242x
        let position_x__10242x: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "position.x"
            keyframeAnimation.values = [60.39, 70.96, 60.39]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let position_y__10242x: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "position.y"
            keyframeAnimation.values = [60.39, 70.96, 60.39]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let bounds_size_width__10242x: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "bounds.size.width"
            keyframeAnimation.values = [120, 141.96, 120]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let bounds_size_height__10242x: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "bounds.size.height"
            keyframeAnimation.values = [120, 141.96, 120]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
         
        // Keyframe Animations for path
        let position_x_path: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "position.x"
            keyframeAnimation.values = [70.81, 83.73, 70.81]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let position_y_path: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "position.y"
            keyframeAnimation.values = [27.59, 32.64, 27.59]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let bounds_size_width_path: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "bounds.size.width"
            keyframeAnimation.values = [55.2, 65.27, 55.2]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let bounds_size_height_path: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "bounds.size.height"
            keyframeAnimation.values = [55.2, 65.27, 55.2]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let path_path: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "path"
            keyframeAnimation.values = [CGPathCreateWithSVGString("M0,7.2c0,-3.976,3.224,-7.2,7.2,-7.2 26.51,0,48,21.49,48,48 0,3.976,-3.224,7.2,-7.2,7.2 -3.976,0,-7.2,-3.224,-7.2,-7.2 0,-18.557,-15.043,-33.6,-33.6,-33.6 -3.976,0,-7.2,-3.224,-7.2,-7.2zM0,7.2")!, CGPathCreateWithSVGString("M0,8.513c0,-4.702,3.812,-8.513,8.513,-8.513 31.346,0,56.757,25.411,56.757,56.757 0,4.702,-3.812,8.513,-8.513,8.513 -4.702,0,-8.513,-3.812,-8.513,-8.513 0,-21.942,-17.787,-39.73,-39.73,-39.73 -4.702,0,-8.513,-3.812,-8.513,-8.513zM0,8.513")!, CGPathCreateWithSVGString("M0,7.2c0,-3.976,3.224,-7.2,7.2,-7.2 26.51,0,48,21.49,48,48 0,3.976,-3.224,7.2,-7.2,7.2 -3.976,0,-7.2,-3.224,-7.2,-7.2 0,-18.557,-15.043,-33.6,-33.6,-33.6 -3.976,0,-7.2,-3.224,-7.2,-7.2zM0,7.2")!]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
         
        // Keyframe Animations for path_1
        let position_x_path_1: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "position.x"
            keyframeAnimation.values = [49.2, 58.19, 49.2]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let position_y_path_1: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "position.y"
            keyframeAnimation.values = [92.41, 109.27, 92.41]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let bounds_size_width_path_1: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "bounds.size.width"
            keyframeAnimation.values = [55.2, 65.27, 55.2]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let bounds_size_height_path_1: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "bounds.size.height"
            keyframeAnimation.values = [55.2, 65.27, 55.2]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let path_path_1: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "path"
            keyframeAnimation.values = [CGPathCreateWithSVGString("M55.2,48c0,3.976,-3.224,7.2,-7.2,7.2 -26.51,0,-48,-21.49,-48,-48 0,-3.976,3.224,-7.2,7.2,-7.2 3.976,0,7.2,3.224,7.2,7.2 0,18.557,15.043,33.6,33.6,33.6 3.976,0,7.2,3.224,7.2,7.2zM55.2,48")!, CGPathCreateWithSVGString("M65.27,56.757c0,4.702,-3.812,8.513,-8.513,8.513 -31.346,0,-56.757,-25.411,-56.757,-56.757 0,-4.702,3.812,-8.513,8.513,-8.513 4.702,0,8.513,3.812,8.513,8.513 0,21.942,17.787,39.73,39.73,39.73 4.702,0,8.513,3.812,8.513,8.513zM65.27,56.757")!, CGPathCreateWithSVGString("M55.2,48c0,3.976,-3.224,7.2,-7.2,7.2 -26.51,0,-48,-21.49,-48,-48 0,-3.976,3.224,-7.2,7.2,-7.2 3.976,0,7.2,3.224,7.2,7.2 0,18.557,15.043,33.6,33.6,33.6 3.976,0,7.2,3.224,7.2,7.2zM55.2,48")!]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
         
        // Keyframe Animations for path_2
        let position_x_path_2: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "position.x"
            keyframeAnimation.values = [27.59, 32.64, 27.59]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let position_y_path_2: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "position.y"
            keyframeAnimation.values = [49.2, 58.19, 49.2]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let bounds_size_width_path_2: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "bounds.size.width"
            keyframeAnimation.values = [55.2, 65.27, 55.2]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let bounds_size_height_path_2: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "bounds.size.height"
            keyframeAnimation.values = [55.2, 65.27, 55.2]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let path_path_2: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "path"
            keyframeAnimation.values = [CGPathCreateWithSVGString("M7.2,55.2c-3.976,0,-7.2,-3.224,-7.2,-7.2 0,-26.51,21.49,-48,48,-48 3.976,0,7.2,3.224,7.2,7.2 0,3.976,-3.224,7.2,-7.2,7.2 -18.557,0,-33.6,15.043,-33.6,33.6 0,3.976,-3.224,7.2,-7.2,7.2zM7.2,55.2")!, CGPathCreateWithSVGString("M8.513,65.27c-4.702,0,-8.513,-3.812,-8.513,-8.513 0,-31.346,25.411,-56.757,56.757,-56.757 4.702,0,8.513,3.812,8.513,8.513 0,4.702,-3.812,8.513,-8.513,8.513 -21.942,0,-39.73,17.787,-39.73,39.73 0,4.702,-3.812,8.513,-8.513,8.513zM8.513,65.27")!, CGPathCreateWithSVGString("M7.2,55.2c-3.976,0,-7.2,-3.224,-7.2,-7.2 0,-26.51,21.49,-48,48,-48 3.976,0,7.2,3.224,7.2,7.2 0,3.976,-3.224,7.2,-7.2,7.2 -18.557,0,-33.6,15.043,-33.6,33.6 0,3.976,-3.224,7.2,-7.2,7.2zM7.2,55.2")!]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
         
        // Keyframe Animations for path_3
        let position_x_path_3: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "position.x"
            keyframeAnimation.values = [92.41, 109.27, 92.41]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let position_y_path_3: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "position.y"
            keyframeAnimation.values = [70.81, 83.73, 70.81]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let bounds_size_width_path_3: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "bounds.size.width"
            keyframeAnimation.values = [55.2, 65.27, 55.2]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let bounds_size_height_path_3: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "bounds.size.height"
            keyframeAnimation.values = [55.2, 65.27, 55.2]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
        let path_path_3: CAKeyframeAnimation = {
            let keyframeAnimation = CAKeyframeAnimation()
            keyframeAnimation.keyPath = "path"
            keyframeAnimation.values = [CGPathCreateWithSVGString("M48,0c3.976,0,7.2,3.224,7.2,7.2 0,26.51,-21.49,48,-48,48 -3.976,0,-7.2,-3.224,-7.2,-7.2 0,-3.976,3.224,-7.2,7.2,-7.2 18.557,0,33.6,-15.043,33.6,-33.6 0,-3.976,3.224,-7.2,7.2,-7.2zM48,0")!, CGPathCreateWithSVGString("M56.757,0c4.702,0,8.513,3.812,8.513,8.513 0,31.346,-25.411,56.757,-56.757,56.757 -4.702,0,-8.513,-3.812,-8.513,-8.513 0,-4.702,3.812,-8.513,8.513,-8.513 21.942,0,39.73,-17.787,39.73,-39.73 0,-4.702,3.812,-8.513,8.513,-8.513zM56.757,0")!, CGPathCreateWithSVGString("M48,0c3.976,0,7.2,3.224,7.2,7.2 0,26.51,-21.49,48,-48,48 -3.976,0,-7.2,-3.224,-7.2,-7.2 0,-3.976,3.224,-7.2,7.2,-7.2 18.557,0,33.6,-15.043,33.6,-33.6 0,-3.976,3.224,-7.2,7.2,-7.2zM48,0")!]
            keyframeAnimation.keyTimes = [0, 0.5, 1]
            keyframeAnimation.timingFunctions = [.easeInEaseOut, .easeInEaseOut]
            keyframeAnimation.duration = duration
            
            return keyframeAnimation
        }()
         
        // Organize CAKeyframeAnimations by CALayer
        var animationsByLayer = [CALayer: [CAKeyframeAnimation]]()
        animationsByLayer[view._10242x.layer] = [position_x__10242x, position_y__10242x, bounds_size_height__10242x, bounds_size_width__10242x]
        animationsByLayer[view.path.layer] = [position_y_path, bounds_size_height_path, bounds_size_width_path, position_x_path, path_path]
        animationsByLayer[view.path_1.layer] = [position_y_path_1, bounds_size_width_path_1, bounds_size_height_path_1, position_x_path_1, path_path_1]
        animationsByLayer[view.path_2.layer] = [position_y_path_2, bounds_size_height_path_2, position_x_path_2, bounds_size_width_path_2, path_path_2]
        animationsByLayer[view.icon.layer] = [backgroundcolor_icon, bounds_size_width_icon, position_x_icon, position_y_icon, bounds_size_height_icon, transform_rotation_z_icon]
        animationsByLayer[view.path_3.layer] = [position_y_path_3, bounds_size_height_path_3, bounds_size_width_path_3, position_x_path_3, path_path_3]

        return animationsByLayer
    }
}
