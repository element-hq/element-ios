/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

@objcMembers
/// Avoid keyboard overlap with scroll view content
final class KeyboardAvoider: NSObject {
    
    // MARK: - Constants
    
    private enum KeyboardAnimation {
        static let defaultDuration: TimeInterval = 0.25
        static let defaultAnimationCurveRawValue: Int = UIView.AnimationCurve.easeInOut.rawValue
    }
    
    // MARK: - Properties
    
    weak var scrollViewContainerView: UIView?
    weak var scrollView: UIScrollView?
    
    // MARK: - Setup
    
    /// Designated initializer.
    ///
    /// - Parameter scrollViewContainerView: The view that wraps the scroll view.
    /// - Parameter scrollView: The scroll view containing keyboard inputs and where content view overlap with keyboard should be avoided.
    init(scrollViewContainerView: UIView, scrollView: UIScrollView) {
        self.scrollViewContainerView = scrollViewContainerView
        self.scrollView = scrollView
        super.init()
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
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(keyboardWillHide(notification:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
    }
    
    private func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
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
        let scrollViewBottomInset = max(scrollView.frame.maxY - keyboardFrameInView.origin.y - view.safeAreaInsets.bottom, 0)
        
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
