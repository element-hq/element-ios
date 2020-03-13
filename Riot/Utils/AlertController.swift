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
import UIKit

@objcMembers
class AlertController: UIAlertController {
    
    var buttonBackgroundColor: UIColor =
        ThemeService.shared().themeId == "black" ?
            ThemeService.shared().theme(withThemeId: "dark").backgroundColor :
            ThemeService.shared().theme.backgroundColor {
        didSet {
            // Invalidate current colors on change.
            view.setNeedsLayout()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        NSLog("[AlertController] theme id \(ThemeService.shared().themeId ?? "empty")")
        
        view.allViews.forEach {
            // If there was any non-clear background color, update to custom background.
            if let color = $0.backgroundColor, color != .clear {
                $0.backgroundColor = buttonBackgroundColor
            }
            // If view is UIVisualEffectView, remove it's effect and customise color.
            if let visualEffectView = $0 as? UIVisualEffectView {
                visualEffectView.effect = nil
                visualEffectView.backgroundColor = buttonBackgroundColor
            }
        }
        
        // Update background color of popoverPresentationController (for iPads).
        popoverPresentationController?.backgroundColor = buttonBackgroundColor
    }
}


extension UIView {
    /// All child subviews in view hierarchy plus self.
    fileprivate var allViews: [UIView] {
        var views = [self]
        subviews.forEach {
            views.append(contentsOf: $0.allViews)
        }
        
        return views
    }
}
