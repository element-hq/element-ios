/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

extension UISearchBar {
    
    /// Returns internal UITextField
    @objc var vc_searchTextField: UITextField? {
        // TODO: To remove once on XCode11/iOS13
        #if swift(>=5.1)
            if #available(iOS 13.0, *) {
                return self.searchTextField
            } else {
                return self.value(forKey: "searchField") as? UITextField
            }
        #else
            return self.value(forKey: "searchField") as? UITextField
        #endif
    }
}
