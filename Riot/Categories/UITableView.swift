/*
Copyright 2024 New Vector Ltd.
Copyright 2020 Vector Creations Ltd
Copyright 2014 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
