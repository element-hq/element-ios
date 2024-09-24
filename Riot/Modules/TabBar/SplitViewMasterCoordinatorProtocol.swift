// File created from FlowTemplate
// $ createRootCoordinator.sh TabBar TabBar
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
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
