// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import UIKit
import Reusable

class PaginationLoadingViewCell: UITableViewCell, NibReusable, Themable {
    
    // MARK: - Properties
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.activityIndicator.tintColor = theme.colors.tertiaryContent
        self.activityIndicator.startAnimating()
    }
}
