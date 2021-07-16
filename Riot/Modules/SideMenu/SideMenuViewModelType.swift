// File created from ScreenTemplate
// $ createScreen.sh SideMenu SideMenu
/*
 Copyright 2020 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
