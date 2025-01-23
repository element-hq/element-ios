// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import PostHog

extension PostHogConfig {
    static var standard: PostHogConfig? {
        let analyticsConfiguration = BuildSettings.analyticsConfiguration
        guard analyticsConfiguration.isEnabled else { return nil }
        
        let postHogConfiguration = PostHogConfig(apiKey: analyticsConfiguration.apiKey, host: analyticsConfiguration.host)
        // We capture screens manually
        postHogConfiguration.captureScreenViews = false


        return postHogConfiguration
    }
}
