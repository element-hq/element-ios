// 
// Copyright 2020 New Vector Ltd
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

protocol SplitViewMasterPresentableDelegate: AnyObject {
    
    /// Detail items from the split view
    var detailModules: [Presentable] { get }
    
    /// Shared presenter of user indicators for detail views, such as rooms
    var detailUserIndicatorPresenter: UserIndicatorTypePresenterProtocol? { get }
    
    /// Replace split view detail with the given detailPresentable
    func splitViewMasterPresentable(_ presentable: Presentable, wantsToReplaceDetailWith detailPresentable: Presentable, popCompletion: (() -> Void)?)
    
    /// Stack the detailPresentable on the existing split view detail stack
    func splitViewMasterPresentable(_ presentable: Presentable, wantsToStack detailPresentable: Presentable, popCompletion: (() -> Void)?)
    
    /// Replace split view detail with the given modules
    func splitViewMasterPresentable(_ presentable: Presentable, wantsToReplaceDetailsWith modules: [NavigationModule])
    
    /// Stack modules on the existing split view detail stack
    func splitViewMasterPresentable(_ presentable: Presentable, wantsToStack modules: [NavigationModule])
    
    /// Pop to module on the existing split view detail stack
    func splitViewMasterPresentable(_ presentable: Presentable, wantsToPopTo module: Presentable)
    
    /// Reset detail stack with placeholder
    func splitViewMasterPresentableWantsToResetDetail(_ presentable: Presentable)
}

/// `SplitViewMasterPresentableDelegate` default implementation
extension SplitViewMasterPresentableDelegate {
    func splitViewMasterPresentable(_ presentable: Presentable, wantsToDisplay detailPresentable: Presentable) {
        splitViewMasterPresentable(presentable, wantsToReplaceDetailWith: detailPresentable, popCompletion: nil)
    }
}

/// Protocol used by the master view presentable of a UISplitViewController
protocol SplitViewMasterPresentable: AnyObject, Presentable {
        
    var splitViewMasterPresentableDelegate: SplitViewMasterPresentableDelegate? { get set }    
    
    /// Return the currently selected and visible NavigationRouter
    /// It will be used to manage detail controllers
    var selectedNavigationRouter: NavigationRouterType? { get }
}
