// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
