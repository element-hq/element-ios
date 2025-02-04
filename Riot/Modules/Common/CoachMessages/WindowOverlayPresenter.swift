// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

/// `WindowOverlayPresenter` allows to add a given view to the presenting view or window.
/// The presenter also manages taps over the presenting view and the duration to dismiss the view.
class WindowOverlayPresenter: NSObject {
    
    // MARK: Private

    private weak var presentingView: UIView?
    private weak var presentedView: UIView?
    private weak var gestureRecognizer: UIGestureRecognizer?
    private var timer: Timer?

    // MARK: Public

    /// Add a given view to the presenting view or window.
    /// The presenter also manages taps over the presenting view and the duration to dismiss the view.
    ///
    /// - parameters:
    ///     - view: instance of the view that will be displayed
    ///     - presentingView: instance of the presenting view. `nil` will display the view over the key window
    ///     - duration:if duration is not `nil`, the view will be dismissed after the given duration. The view is never dismissed otherwise
    func show(_ view: UIView, over presentingView: UIView? = nil, duration: TimeInterval? = nil) {
        guard presentedView == nil else {
            return
        }
        
        let keyWindow: UIWindow? = UIApplication.shared.windows.filter {$0.isKeyWindow}.first

        guard let backView = presentingView ?? keyWindow else {
            MXLog.error("[WindowOverlay] show: no eligible presenting view found")
            return
        }
        
        view.alpha = 0
        
        backView.addSubview(view)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didTapOnBackView(sender:)))
        tapGestureRecognizer.cancelsTouchesInView = false
        backView.addGestureRecognizer(tapGestureRecognizer)
        self.gestureRecognizer = tapGestureRecognizer
        
        self.presentingView = backView
        self.presentedView = view
        
        UIView.animate(withDuration: 0.3) {
            view.alpha = 1
        }
        
        if let timeout = duration {
            timer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false, block: { [weak self] timer in
                self?.dismiss()
            })
        }
    }
    
    /// Dismisses the currently presented view.
    func dismiss() {
        if let gestureRecognizer = self.gestureRecognizer {
            self.presentingView?.removeGestureRecognizer(gestureRecognizer)
        }
        self.timer?.invalidate()
        self.timer = nil

        UIView.animate(withDuration: 0.3) {
            self.presentedView?.alpha = 0
        } completion: { isFinished in
            if isFinished {
                self.presentedView?.removeFromSuperview()
                self.presentingView = nil
            }
        }

    }
    
    // MARK: Private

    @objc private func didTapOnBackView(sender: UIGestureRecognizer) {
        dismiss()
    }
}

// MARK: Objective-C
extension WindowOverlayPresenter {
    /// Add a given view to the presenting view or window.
    /// The presenter also manages taps over the presenting view and the duration to dismiss the view.
    ///
    /// - parameters:
    ///     - view: instance of the view that will be displayed
    ///     - presentingView: instance of the presenting view. `nil` will display the view over the key window
    ///     - duration:if duration > 0, the view will be dismissed after the given duration. The view is never dismissed otherwise
    @objc func show(_ view: UIView, over presentingView: UIView?, duration: TimeInterval) {
        self.show(view, over: presentingView, duration: duration > 0 ? duration : nil)
    }
}
