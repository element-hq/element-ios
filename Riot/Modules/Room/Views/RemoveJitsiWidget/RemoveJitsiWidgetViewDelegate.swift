// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objc
protocol RemoveJitsiWidgetViewDelegate: AnyObject {
    
    /// Tells the delegate that the user complete sliding on the view
    /// - Parameter view: The view instance
    func removeJitsiWidgetViewDidCompleteSliding(_ view: RemoveJitsiWidgetView)
}
