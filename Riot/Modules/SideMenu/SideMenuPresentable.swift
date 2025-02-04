// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// SideMenuPresentable absract a side menu presenter
protocol SideMenuPresentable {
    
    /// Show side menu
    func show(from presentable: Presentable, animated: Bool, completion: (() -> Void)?)
    
    /// Hide side menu
    func dismiss(animated: Bool, completion: (() -> Void)?)
    
    /// Add screen edge gesture to reveal menu
    @discardableResult func addScreenEdgePanGesturesToPresent(to view: UIView) -> UIScreenEdgePanGestureRecognizer
    
    /// Add pan gesture to reveal menu, like pan to reveal from a navigation bar
    @discardableResult func addPanGestureToPresent(to view: UIView) -> UIPanGestureRecognizer
}

// MARK: Default implementation
extension SideMenuPresentable {
    
    func show(from presentable: Presentable, animated: Bool) {
        return self.show(from: presentable, animated: animated, completion: nil)
    }
    
    func dismiss(animated: Bool) {
        return self.dismiss(animated: animated, completion: nil)
    }
}
