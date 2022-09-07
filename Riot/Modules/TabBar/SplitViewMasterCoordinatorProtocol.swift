// File created from FlowTemplate
// $ createRootCoordinator.sh TabBar TabBar
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

protocol SplitViewMasterCoordinatorDelegate: AnyObject {
    // TODO: Remove this method, authentication should not be handled by SplitViewMasterCoordinator
    func splitViewMasterCoordinatorDidCompleteAuthentication(_ coordinator: SplitViewMasterCoordinatorProtocol)
}

/// `SplitViewMasterCoordinatorProtocol` is a protocol describing a Coordinator that handle the master view controller of the `UISplitViewController`
protocol SplitViewMasterCoordinatorProtocol: Coordinator, SplitViewMasterPresentable {
    
    var delegate: SplitViewMasterCoordinatorDelegate? { get }
        
    /// Start coordinator by selecting a Space.
    /// - Parameter spaceId: The id of the Space to use.
    func start(with spaceId: String?)
    
    func popToHome(animated: Bool, completion: (() -> Void)?)
    
    // TODO: Remove this method, this implementation detail should not be exposed
    // Release the current selected item (room/contact/group...).
    func releaseSelectedItems()
    
    /// Displays an error using a `UserIndicator`. The messages is dimissed automatically.
    func showErroIndicator(with error: Error)
    
    /// Displays an message related to the application state using a `UserIndicator`. The message must be dimissed by calling the method `hideAppStateIndicator()`
    func showAppStateIndicator(with text: String, icon: UIImage?)
    
    /// Hide the message related to the application state currently displayed.
    func hideAppStateIndicator()
}
