// 
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest
@testable import Element
import AnalyticsEvents

class PostHogAnalyticsClientTests: XCTestCase {
    
    private var posthogMock: MockPostHog!
    
    override func setUp() {
        posthogMock = MockPostHog()
    }
    
    func testSuperPropertiesAddedToAllCaptured() {
        let analyticsClient = PostHogAnalyticsClient(posthogFactory: MockPostHogFactory(mock: posthogMock))
        analyticsClient.start()
        
        let superProperties = AnalyticsEvent.SuperProperties(appPlatform: .EI, cryptoSDK: .Rust, cryptoSDKVersion: "0.0")
        
        analyticsClient.updateSuperProperties(superProperties)
        // It should be the same for any event
        let someEvent = AnalyticsEvent.CallEnded(durationMs: 0, isVideo: false, numParticipants: 1, placed: true)
        analyticsClient.capture(someEvent)
        
        let capturedEvent = posthogMock.capturePropertiesUserPropertiesReceivedArguments
        
        // All the super properties should have been added
        XCTAssertEqual(capturedEvent?.properties?["cryptoSDK"] as? String, AnalyticsEvent.SuperProperties.CryptoSDK.Rust.rawValue)
        XCTAssertEqual(capturedEvent?.properties?["appPlatform"] as? String, AnalyticsEvent.SuperProperties.AppPlatform.EI.rawValue)
        XCTAssertEqual(capturedEvent?.properties?["cryptoSDKVersion"] as? String, "0.0")
        
        // Other properties should be there
        XCTAssertEqual(capturedEvent?.properties?["isVideo"] as? Bool, false)
        
        // Should also work for screens
        
        analyticsClient.screen(AnalyticsEvent.MobileScreen.init(durationMs: 0, screenName: .Home))
        
        
        let capturedScreen = posthogMock.screenPropertiesReceivedArguments
        
        
        XCTAssertEqual(capturedScreen?.properties?["cryptoSDK"] as? String, AnalyticsEvent.SuperProperties.CryptoSDK.Rust.rawValue)
        XCTAssertEqual(capturedScreen?.properties?["appPlatform"] as? String, AnalyticsEvent.SuperProperties.AppPlatform.EI.rawValue)
        XCTAssertEqual(capturedScreen?.properties?["cryptoSDKVersion"] as? String, "0.0")
        
        
        XCTAssertEqual(capturedScreen?.screenTitle, AnalyticsEvent.MobileScreen.ScreenName.Home.rawValue)
        
        
    }
    
    func testSuperPropertiesCanBeUdpated() {
        let analyticsClient = PostHogAnalyticsClient(posthogFactory: MockPostHogFactory(mock: posthogMock))
        analyticsClient.start()
        
        let superProperties = AnalyticsEvent.SuperProperties(appPlatform: .EI, cryptoSDK: .Rust, cryptoSDKVersion: "0.0")
        
        analyticsClient.updateSuperProperties(superProperties)
        // It should be the same for any event
        let someEvent = AnalyticsEvent.CallEnded(durationMs: 0, isVideo: false, numParticipants: 1, placed: true)
        analyticsClient.capture(someEvent)
        
        let capturedEvent = posthogMock.capturePropertiesUserPropertiesReceivedArguments
        
        //
        XCTAssertEqual(capturedEvent?.properties?["cryptoSDKVersion"] as? String, "0.0")
        
        analyticsClient.updateSuperProperties(AnalyticsEvent.SuperProperties(appPlatform: .EI, cryptoSDK: .Rust, cryptoSDKVersion: "1.0"))
        
        
        analyticsClient.capture(someEvent)
        
        let secondCapturedEvent = posthogMock.capturePropertiesUserPropertiesReceivedArguments
        
        XCTAssertEqual(secondCapturedEvent?.properties?["cryptoSDKVersion"] as? String, "1.0")
    }
    
    func testSuperPropertiesDontOverrideEventProperties() {
        let analyticsClient = PostHogAnalyticsClient(posthogFactory: MockPostHogFactory(mock: posthogMock))
        analyticsClient.start()
        
        // Super property for cryptoSDK is rust
        let superProperties = AnalyticsEvent.SuperProperties(appPlatform: nil, cryptoSDK: .Rust, cryptoSDKVersion: nil)
        
        analyticsClient.updateSuperProperties(superProperties)
        
        // This event as a similar named property `cryptoSDK` with Legacy value
        let someEvent = AnalyticsEvent.Error(context: nil, cryptoModule: nil, cryptoSDK: .Legacy, domain: .E2EE, eventLocalAgeMillis: nil, isFederated: nil, isMatrixDotOrg: nil, name: .OlmKeysNotSentError, timeToDecryptMillis: nil, userTrustsOwnIdentity: nil, wasVisibleToUser: nil)
        
        analyticsClient.capture(someEvent)
        
        let capturedEvent = posthogMock.capturePropertiesUserPropertiesReceivedArguments
        
        XCTAssertEqual(capturedEvent?.properties?["cryptoSDK"] as? String, AnalyticsEvent.Error.CryptoSDK.Legacy.rawValue)
    }
        
}
