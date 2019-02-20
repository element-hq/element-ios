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

import UIKit

/// Wrapper for the Notification userInfo values associated with a keyboard notification.
public struct KeyboardNotification {
    
    let userInfo: [AnyHashable: Any]
    
    public init?(notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return nil
        }
        self.userInfo = userInfo
    }
    
    public var keyboardFrameBegin: CGRect? {
        guard let value = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue else {
            return nil
        }
        return value.cgRectValue
    }
    
    public var keyboardFrameEnd: CGRect? {
        guard let value = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return nil
        }
        return value.cgRectValue
    }
    
    public var animationDuration: TimeInterval? {
        guard let number = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber else {
            return nil
        }
        return number.doubleValue
    }
    
    /// Keyboard UIViewAnimationCurve enum raw value
    public var animationCurveRawValue: Int? {
        guard let number = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber else {
            return nil
        }
        return number.intValue
    }
    
    /// Convert UIViewAnimationCurve raw value to UIViewAnimationOptions
    public func animationOptions(fallbackAnimationCurveValue: Int = UIView.AnimationCurve.easeInOut.rawValue) -> UIView.AnimationOptions {
        let animationCurveRawValue = self.animationCurveRawValue ?? fallbackAnimationCurveValue
        return UIView.AnimationOptions(rawValue: UInt(animationCurveRawValue << 16))
    }
}
