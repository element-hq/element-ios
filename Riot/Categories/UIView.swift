/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

extension UIView {
    
    /// Add a subview matching parent view using autolayout
    @objc func vc_addSubViewMatchingParent(_ subView: UIView) {
        self.addSubview(subView)
        subView.translatesAutoresizingMaskIntoConstraints = false
        let views = ["view": subView]
        ["H:|[view]|", "V:|[view]|"].forEach { vfl in
            let constraints = NSLayoutConstraint.constraints(withVisualFormat: vfl,
                                                             options: [],
                                                             metrics: nil,
                                                             views: views)
            constraints.forEach { $0.isActive = true }
        }
    }
    
    @objc func vc_removeAllSubviews() {
        for subView in self.subviews {
            subView.removeFromSuperview()
        }
    }
    
    /// Shake the view to indicate an error
    @objc func vc_shake() {
        let shake = CABasicAnimation(keyPath: "position")
        let xDelta = CGFloat(10)
        shake.duration = 0.07
        shake.repeatCount = 2
        shake.autoreverses = true

        let fromPoint = CGPoint(x: center.x - xDelta, y: center.y)
        let toPoint = CGPoint(x: center.x + xDelta, y: center.y)

        shake.fromValue = NSValue(cgPoint: fromPoint)
        shake.toValue = NSValue(cgPoint: toPoint)
        shake.timingFunction = CAMediaTimingFunction(name: .easeOut)
        layer.add(shake, forKey: "position")
    }
    
    @objc func vc_setupAccessibilityTraitsButton(withTitle title: String, hint: String, isEnabled: Bool) {
        self.isAccessibilityElement = true
        self.accessibilityLabel = title
        self.accessibilityHint = hint
        self.accessibilityTraits = .button
        if !isEnabled {
            self.accessibilityTraits.insert(.notEnabled)
        }
    }
}
