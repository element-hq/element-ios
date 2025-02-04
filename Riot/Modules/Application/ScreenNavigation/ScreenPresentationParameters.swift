// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Screen presentation parameters used when a universal link is triggered
@objcMembers
class ScreenPresentationParameters: NSObject {
    
    // MARK: - Properties
    
    /// Indicate to pop to home and restore initial view hierarchy
    let restoreInitialDisplay: Bool
    
    /// Indicate to stack above visible views
    /// If this variable is set to true `restoreInitialDisplay` should be set to false to have effect
    let stackAboveVisibleViews: Bool
    
    /// The object that triggers the universal link action.
    let sender: AnyObject?
    
    /// The view containing the anchor rectangle for the popover. Useful for iPad if a universlink trigger a pop over.
    let sourceView: UIView?
        
    /// The view controller from which the universal link is triggered. `nil` if triggered from some other kind of object.
    var presentingViewController: UIViewController? {
        return self.sender as? UIViewController
    }
    
    // MARK: - Properties
    
    init(restoreInitialDisplay: Bool,
         stackAboveVisibleViews: Bool,
         sender: AnyObject?,
         sourceView: UIView?) {
        self.restoreInitialDisplay = restoreInitialDisplay
        self.stackAboveVisibleViews = stackAboveVisibleViews
        self.sender = sender
        self.sourceView = sourceView
        
        super.init()
    }    
    
    convenience init(restoreInitialDisplay: Bool, stackAboveVisibleViews: Bool) {
        self.init(restoreInitialDisplay: restoreInitialDisplay, stackAboveVisibleViews: stackAboveVisibleViews, sender: nil, sourceView: nil)
    }
    
    /// In this initializer `stackAboveVisibleViews` is set to false`
    convenience init(restoreInitialDisplay: Bool) {
        self.init(restoreInitialDisplay: restoreInitialDisplay, stackAboveVisibleViews: false, sender: nil, sourceView: nil)
    }
}
