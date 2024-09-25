/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
