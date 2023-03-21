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
import XCTest
@testable import Element

class CryptoSDKFeatureTests: XCTestCase {
    class RemoteFeatureClient: RemoteFeaturesClientProtocol {
        var isEnabled = false
        func isFeatureEnabled(_ feature: String) -> Bool {
            isEnabled
        }
    }
    
    var remote: RemoteFeatureClient!
    var feature: CryptoSDKFeature!
    
    override func setUp() {
        RiotSettings.shared.enableCryptoSDK = false
        remote = RemoteFeatureClient()
        feature = CryptoSDKFeature(remoteFeature: remote, localTargetPercentage: 0)
    }
    
    override func tearDown() {
        RiotSettings.shared.enableCryptoSDK = false
    }
    
    func test_disabledByDefault() {
        XCTAssertFalse(feature.isEnabled)
    }
    
    func test_enable() {
        feature.enable()
        XCTAssertTrue(feature.isEnabled)
    }
    
    func test_enableIfAvailable_remainsEnabledWhenRemoteClientDisabled() {
        feature.enable()
        remote.isEnabled = false
        
        feature.enableIfAvailable(forUserId: "alice")
        
        XCTAssertTrue(feature.isEnabled)
    }
    
    func test_enableIfAvailable_notEnabledIfRemoteFeatureDisabled() {
        remote.isEnabled = false
        feature.enableIfAvailable(forUserId: "alice")
        XCTAssertFalse(feature.isEnabled)
    }
    
    func test_canManuallyEnable() {
        remote.isEnabled = false
        XCTAssertTrue(feature.canManuallyEnable(forUserId: "alice"))
        
        remote.isEnabled = true
        XCTAssertFalse(feature.canManuallyEnable(forUserId: "alice"))
    }
    
    func test_reset() {
        feature.enable()
        feature.reset()
        XCTAssertFalse(RiotSettings.shared.enableCryptoSDK)
    }
}
