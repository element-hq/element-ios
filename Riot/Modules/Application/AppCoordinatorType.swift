/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

/// `AppCoordinatorType` is a protocol describing a Coordinator that handles application navigation flow. 
protocol AppCoordinatorType: Coordinator {
    
    func open(url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool
}
