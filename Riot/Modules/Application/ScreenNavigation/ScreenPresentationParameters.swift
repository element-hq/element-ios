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
