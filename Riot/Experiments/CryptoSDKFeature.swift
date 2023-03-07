// 
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

/// An implementation of `MXCryptoV2Feature` which uses `UserDefaults` to persist the enabled status
/// of `CryptoSDK`, and which uses feature flags to control rollout availability.
///
/// The implementation uses both remote and local feature flags to control the availability of `CryptoSDK`.
/// Whilst remote is more convenient in that it allows changes to the rollout without new app releases,
/// it is not available to all users because it requires data tracking user consent. Remote therefore
/// represents the safer, albeit limited rollout strategy, whereas the local feature flags allows eventually
/// targetting all users, but each target change requires new app release.
///
/// Additionally users can manually enable this feature from the settings if they are not already in the
/// feature group.
@objc class CryptoSDKFeature: NSObject, MXCryptoV2Feature {
    @objc static let shared = CryptoSDKFeature()
    
    var isEnabled: Bool {
        RiotSettings.shared.enableCryptoSDK
    }
    
    private static let FeatureName = "ios-crypto-sdk"
    private let remoteFeature: RemoteFeaturesClientProtocol
    private let localFeature: PhasedRolloutFeature
    
    init(remoteFeature: RemoteFeaturesClientProtocol = PostHogAnalyticsClient.shared) {
        self.remoteFeature = remoteFeature
        self.localFeature = PhasedRolloutFeature(
            name: Self.FeatureName,
            // Local feature is currently set to 0% target, and all availability is fully controlled
            // by the remote feature. Once the remote is fully rolled out, target for local feature will
            // be gradually increased.
            targetPercentage: 0.0
        )
    }
    
    func enable() {
        RiotSettings.shared.enableCryptoSDK = true
        Analytics.shared.trackCryptoSDKEnabled()
        
        MXLog.debug("[CryptoSDKFeature] Crypto SDK enabled")
    }
    
    func enableIfAvailable(forUserId userId: String!) {
        guard !isEnabled else {
            MXLog.debug("[CryptoSDKFeature] enableIfAvailable: Feature is already enabled")
            return
        }
        
        guard let userId else {
            MXLog.failure("[CryptoSDKFeature] enableIfAvailable: Missing user id")
            return
        }
        
        guard isFeatureEnabled(userId: userId) else {
            MXLog.debug("[CryptoSDKFeature] enableIfAvailable: Feature is currently not available for this user")
            return
        }
        
        MXLog.debug("[CryptoSDKFeature] enableIfAvailable: Feature has become available for this user and will be enabled")
        enable()
    }
    
    @objc func canManuallyEnable(forUserId userId: String!) -> Bool {
        guard let userId else {
            MXLog.failure("[CryptoSDKFeature] canManuallyEnable: Missing user id")
            return false
        }
        
        // User can manually enable only if not already within the automatic feature group
        return !isFeatureEnabled(userId: userId)
    }
    
    @objc func reset() {
        RiotSettings.shared.enableCryptoSDK = false
        MXLog.debug("[CryptoSDKFeature] Crypto SDK disabled")
    }
    
    private func isFeatureEnabled(userId: String) -> Bool {
        remoteFeature.isFeatureEnabled(Self.FeatureName) || localFeature.isEnabled(userId: userId)
    }
}
