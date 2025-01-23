// 
// Copyright 2024 New Vector Ltd.
// Copyright 2020 Vector Creations Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension UIScrollView {
    
    /// Scroll to the given view, which must be a view in the scrollView.
    /// - Parameters:
    ///   - view: The view to scroll
    ///   - insets: Insets for the scroll area. Provide negative values for more visible area than the view's frame
    ///   - animated: animate the scroll
    @objc func vc_scroll(to view: UIView, with insets: UIEdgeInsets = .zero, animated: Bool = true) {
        //  find the view's frame in the scrollView with given insets
        let rect = view.convert(view.frame, to: self).inset(by: insets)
        DispatchQueue.main.async {
            self.scrollRectToVisible(rect, animated: animated)
        }
    }

    /// Scroll to bottom of the receiver.
    /// - Parameter animated: animate the scroll
    @objc func vc_scrollToBottom(animated: Bool = true) {
        guard contentSize.height >= bounds.height else {
            return
        }
        let bottomOffset = CGPoint(x: 0, y: contentSize.height - bounds.height + contentInset.bottom)
        if contentOffset != bottomOffset {
            //  scroll only if not already there
            setContentOffset(bottomOffset, animated: animated)
        }
    }
    
}
