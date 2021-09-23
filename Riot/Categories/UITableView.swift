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

extension UITableView {

    /// Returns safe area insetted separator inset. Should only be used when custom constraints on custom table view cells are being set according to separator insets.
    @objc var vc_separatorInset: UIEdgeInsets {
        var result = separatorInset
        result.left -= self.safeAreaInsets.left
        result.right -= self.safeAreaInsets.right
        return result
    }
    
    /// Since UITableView does not manage Auto Layout for header, it'd be appropriate calling this after tableView bounds change
    @objc func vc_relayoutHeaderView() {
        guard let headerView = tableHeaderView else { return }
        let height = ceil(headerView.systemLayoutSizeFitting(CGSize(width: bounds.width, height: 0),
                                                             withHorizontalFittingPriority: .required,
                                                             verticalFittingPriority: .fittingSizeLevel).height)
        
        //  compare heights to avoid infinite loop
        if height != headerView.frame.height {
            var headerFrame = headerView.frame
            headerFrame.size.height = height
            headerView.frame = headerFrame
            tableHeaderView = headerView
        }
    }
    
    /// Since UITableView does not manage Auto Layout for footer, it'd be appropriate calling this after tableView bounds change
    @objc func vc_relayoutFooterView() {
        guard let footerView = tableFooterView else { return }
        let height = ceil(footerView.systemLayoutSizeFitting(CGSize(width: bounds.width, height: 0),
                                                             withHorizontalFittingPriority: .required,
                                                             verticalFittingPriority: .fittingSizeLevel).height)
        
        //  compare heights to avoid infinite loop
        if height != footerView.frame.height {
            var headerFrame = footerView.frame
            headerFrame.size.height = height
            footerView.frame = headerFrame
            tableFooterView = footerView
        }
    }

    /// Checks a given index path exists in the table view
    /// - Parameter indexPath: index path to check
    /// - Returns: True if table view has the index path, otherwise false
    @objc func vc_hasIndexPath(_ indexPath: IndexPath) -> Bool {
        return numberOfSections > indexPath.section
            && numberOfRows(inSection: indexPath.section) > indexPath.row
    }

}
