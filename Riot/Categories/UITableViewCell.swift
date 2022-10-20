/*
 Copyright 2014 OpenMarket Ltd
 Copyright 2020 Vector Creations Ltd
 
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

extension UITableViewCell {
    
    private enum AccessoryImageAlpha {
        static let highlighted: CGFloat = 0.3
    }

    /// Returns safe area insetted separator inset. Should only be used when custom constraints on custom table view cells are being set according to separator insets.
    @objc var vc_separatorInset: UIEdgeInsets {
        var result = separatorInset
        result.left -= self.safeAreaInsets.left
        result.right -= self.safeAreaInsets.right
        return result
    }
    
    // Hide separator for one cell, otherwise use `tableView.separatorStyle = .none`
    @objc func vc_hideSeparator() {
        self.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
    }
    
    @objc func vc_setAccessoryDisclosureIndicator(withTintColor tintColor: UIColor) {
        let disclosureImage = Asset.Images.disclosureIcon.image.withRenderingMode(.alwaysTemplate)
        let disclosureImageView = UIImageView(image: disclosureImage)
        disclosureImageView.tintColor = tintColor
        disclosureImageView.highlightedImage = disclosureImage.vc_withAlpha(AccessoryImageAlpha.highlighted)
        self.accessoryView = disclosureImageView
    }        
    
    @objc func vc_setAccessoryDisclosureIndicator(withTheme theme: Theme) {
        self.vc_setAccessoryDisclosureIndicator(withTintColor: theme.textSecondaryColor)
    }
    
    @objc func vc_setAccessoryDisclosureIndicatorWithCurrentTheme() {
        self.vc_setAccessoryDisclosureIndicator(withTheme: ThemeService.shared().theme)
    }

    @objc var vc_parentViewController: UIViewController? {
        var parent: UIResponder? = self
        while parent != nil {
            parent = parent?.next
            if let viewController = parent as? UIViewController {
                return viewController
            }
        }
        return nil
    }
    
}
