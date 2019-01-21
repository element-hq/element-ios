/*
 Copyright 2018 New Vector Ltd
 
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

/// Avoid keyboard overlap with scroll view content
final class KeyboardAvoider {
    
    // MARK: - Constants
    
    private enum KeyboardAnimation {
        static let defaultDuration: TimeInterval = 0.25
        static let defaultAnimationCurveRawValue: Int = UIViewAnimationCurve.easeInOut.rawValue
    }
    
    // MARK: - Properties
    
    weak var scrollViewContainerView: UIView?
    weak var scrollView: UIScrollView?
    
    // MARK: - Setup
    
    /// Designated initializer.
    ///
    /// - Parameter scrollViewContainerView: The view that wrap the scroll view.
    /// - Parameter scrollView: The scroll view containing keyboard inputs and where content view overlap with keyboard should be avoided.
    init(scrollViewContainerView: UIView, scrollView: UIScrollView) {
        self.scrollViewContainerView = scrollViewContainerView
        self.scrollView = scrollView
    }
    
    // MARK: - Public
    
    /// Start keyboard avoiding
    func startAvoiding() {
        self.registerKeyboardNotifications()
    }
    
    /// Stop keyboard avoiding
    func stopAvoiding() {
        self.unregisterKeyboardNotifications()
    }
    
    // MARK: - Private
    
    private func registerKeyboardNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            self,
            selector: #selector(keyboardWillShow(notification:)),
            name: .UIKeyboardWillShow,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(keyboardWillHide(notification:)),
            name: .UIKeyboardWillHide,
            object: nil)
    }
    
    private func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: Notification) {
        guard let view = self.scrollViewContainerView, let scrollView = self.scrollView else {
            return
        }
        
        guard let keyboardNotification = KeyboardNotification(notification: notification),
            let keyboardFrame = keyboardNotification.keyboardFrameEnd else {
                return
        }
        
        let animationDuration = keyboardNotification.animationDuration ?? KeyboardAnimation.defaultDuration
        
        let animationOptions = keyboardNotification.animationOptions(fallbackAnimationCurveValue: KeyboardAnimation.defaultAnimationCurveRawValue)
        
        // Transform the keyboard's frame into our view's coordinate system
        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
        
        // Find how much the keyboard overlaps the scroll view
        let scrollViewBottomInset = scrollView.frame.maxY - keyboardFrameInView.origin.y
        
        UIView.animate(withDuration: animationDuration,
                       delay: 0.0,
                       options: animationOptions, animations: {
                        
                        scrollView.contentInset.bottom = scrollViewBottomInset
                        scrollView.scrollIndicatorInsets.bottom = scrollViewBottomInset
        }, completion: nil)
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        guard let scrollView = self.scrollView else {
            return
        }
        
        guard let keyboardNotification = KeyboardNotification(notification: notification) else {
            return
        }
        
        let animationDuration = keyboardNotification.animationDuration ?? KeyboardAnimation.defaultDuration
        
        let animationOptions = keyboardNotification.animationOptions(fallbackAnimationCurveValue: KeyboardAnimation.defaultAnimationCurveRawValue)
        
        // Reset scroll view bottom inset to zero
        let scrollViewBottomInset: CGFloat = 0.0
        
        UIView.animate(withDuration: animationDuration,
                       delay: 0.0,
                       options: animationOptions, animations: {
                        scrollView.contentInset.bottom = scrollViewBottomInset
                        scrollView.scrollIndicatorInsets.bottom = scrollViewBottomInset
        }, completion: nil)
    }
}
