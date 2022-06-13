// 
// Copyright 2020 Vector Creations Ltd
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
