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

/// Presentation parameters used when a universla link is triggered
@objcMembers
class UniversalLinkPresentationParameters: NSObject {
    
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
        
    /// The view controller from which the universal link is triggered
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
    
    /// For the moment this initializer assume that `stackAboveVisibleViews = false` means `restoreInitialDisplay = true` and the opposite
    convenience init(stackAboveVisibleViews: Bool) {
        self.init(restoreInitialDisplay: !stackAboveVisibleViews, stackAboveVisibleViews: stackAboveVisibleViews, sender: nil, sourceView: nil)
    }
}
