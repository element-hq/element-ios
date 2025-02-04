// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
