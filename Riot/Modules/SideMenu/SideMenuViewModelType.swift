// File created from ScreenTemplate
// $ createScreen.sh SideMenu SideMenu
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol SideMenuViewModelViewDelegate: AnyObject {
    func sideMenuViewModel(_ viewModel: SideMenuViewModelType, didUpdateViewState viewSate: SideMenuViewState)
}

protocol SideMenuViewModelCoordinatorDelegate: AnyObject {
    func sideMenuViewModel(_ viewModel: SideMenuViewModelType, didTapMenuItem menuItem: SideMenuItem, fromSourceView sourceView: UIView)
}

/// Protocol describing the view model used by `SideMenuViewController`
protocol SideMenuViewModelType {        
        
    var viewDelegate: SideMenuViewModelViewDelegate? { get set }
    var coordinatorDelegate: SideMenuViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: SideMenuViewAction)
}
