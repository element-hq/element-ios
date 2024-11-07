/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

/// Protocol used to present activity indicator on a view
protocol ActivityIndicatorPresenterType {
    func presentActivityIndicator(on view: UIView, animated: Bool, completion: (() -> Void)?)
    func removeCurrentActivityIndicator(animated: Bool, completion: (() -> Void)?)
}

// `ActivityIndicatorPresenterType` default implementation
extension ActivityIndicatorPresenterType {
    func presentActivityIndicator(on view: UIView, animated: Bool) {
        self.presentActivityIndicator(on: view, animated: animated, completion: nil)
    }
    
    func removeCurrentActivityIndicator(animated: Bool) {
        self.removeCurrentActivityIndicator(animated: animated, completion: nil)
    }
}
