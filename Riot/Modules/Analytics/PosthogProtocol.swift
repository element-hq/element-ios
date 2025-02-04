// 
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import PostHog

protocol PostHogProtocol {
    func optIn()
    
    func optOut()
    
    func reset()
    
    func flush()
    
    func capture(_ event: String, properties: [String: Any]?, userProperties: [String: Any]?)
    
    func screen(_ screenTitle: String, properties: [String: Any]?)
    
    func isFeatureEnabled(_ feature: String) -> Bool
    
    func identify(_ distinctId: String)
    
    func identify(_ distinctId: String, userProperties: [String: Any]?)
    
    func isOptOut() -> Bool
}

protocol PostHogFactory {
    func createPostHog(config: PostHogConfig) -> PostHogProtocol
}

class DefaultPostHogFactory: PostHogFactory {
    func createPostHog(config: PostHogConfig) -> PostHogProtocol {
        PostHogSDK.shared.setup(config)
        return PostHogSDK.shared
    }
}

extension PostHogSDK: PostHogProtocol { }
