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
