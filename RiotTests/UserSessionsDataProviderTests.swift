// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import Element

class UserSessionCardViewDataTests: XCTestCase {
    func testOtherSessionsWithCrossSigning() {
        // Given a data provider for a session that can cross sign.
        let mxSession = MockSession(canCrossSign: true)
        let dataProvider = UserSessionsDataProvider(session: mxSession)
        
        // When the verification state of other sessions is requested.
        let deviceA = MockDeviceInfo(deviceID: .otherDeviceA, verified: true)
        let deviceB = MockDeviceInfo(deviceID: .otherDeviceB, verified: false)
        let verificationStateA = dataProvider.verificationState(for: deviceA)
        let verificationStateB = dataProvider.verificationState(for: deviceB)
        
        // Then they should match the verification state from the device info.
        XCTAssertEqual(verificationStateA, .verified)
        XCTAssertEqual(verificationStateB, .unverified)
    }
    
    func testOtherSessionsWithoutCrossSigning() {
        // Given a data provider for a session that can't cross sign.
        let mxSession = MockSession(canCrossSign: false)
        let dataProvider = UserSessionsDataProvider(session: mxSession)
        
        // When the verification state of other sessions is requested.
        let deviceA = MockDeviceInfo(deviceID: .otherDeviceA, verified: true)
        let deviceB = MockDeviceInfo(deviceID: .otherDeviceB, verified: false)
        let verificationStateA = dataProvider.verificationState(for: deviceA)
        let verificationStateB = dataProvider.verificationState(for: deviceB)
        
        // Then they should return an unknown verification state.
        XCTAssertEqual(verificationStateA, .unknown)
        XCTAssertEqual(verificationStateB, .unknown)
    }
    
    func testCurrentDeviceWithCrossSigning() {
        // Given a data provider for a session that can cross sign.
        let mxSession = MockSession(canCrossSign: true)
        let dataProvider = UserSessionsDataProvider(session: mxSession)
        
        // When the verification state of the same session is requested.
        let currentDeviceVerified = MockDeviceInfo(deviceID: .currentDevice, verified: true)
        let currentDeviceUnverified = MockDeviceInfo(deviceID: .currentDevice, verified: false)
        let verificationStateVerified = dataProvider.verificationState(for: currentDeviceVerified)
        let verificationStateUnverified = dataProvider.verificationState(for: currentDeviceUnverified)
        
        // Then the verification state should be unknown.
        XCTAssertEqual(verificationStateVerified, .verified)
        XCTAssertEqual(verificationStateUnverified, .unverified)
    }
    
    func testCurrentDeviceWithoutCrossSigning() {
        // Given a data provider for a session that can't cross sign.
        let mxSession = MockSession(canCrossSign: false)
        let dataProvider = UserSessionsDataProvider(session: mxSession)
        
        // When the verification state of the same session is requested.
        let currentDeviceVerified = MockDeviceInfo(deviceID: .currentDevice, verified: true)
        let currentDeviceUnverified = MockDeviceInfo(deviceID: .currentDevice, verified: false)
        let verificationStateVerified = dataProvider.verificationState(for: currentDeviceVerified)
        let verificationStateUnverified = dataProvider.verificationState(for: currentDeviceUnverified)
        
        // Then the verification state should be unknown.
        XCTAssertEqual(verificationStateVerified, .unverified)
        XCTAssertEqual(verificationStateUnverified, .unverified)
    }
    
    func testDeviceNotHavingCryptoSupportOnVerifiedDevice() {
        let mxSession = MockSession(canCrossSign: true)
        let dataProvider = UserSessionsDataProvider(session: mxSession)
        
        let verificationState = dataProvider.verificationState(for: nil)
        
        XCTAssertEqual(verificationState, .permanentlyUnverified)
    }
    
    func testDeviceNotHavingCryptoSupportOnUnverifiedDevice() {
        let mxSession = MockSession(canCrossSign: false)
        let dataProvider = UserSessionsDataProvider(session: mxSession)
        
        let verificationState = dataProvider.verificationState(for: nil)
        
        XCTAssertEqual(verificationState, .permanentlyUnverified)
    }
    
    func testObsoletedDeviceInformation_someMatch() {
        let mxSession = MockSession(canCrossSign: true)
        let dataProvider = UserSessionsDataProvider(session: mxSession)
        
        let accountDataEvents: [String: Any] = [
            "io.element.matrix_client_information.D": "",
            "foo": ""
        ]
        
        let expectedObsoletedEvents: Set = [
            "io.element.matrix_client_information.D"
        ]
        
        let obsoletedEvents = dataProvider.obsoletedDeviceAccountData(deviceList: .mockDevices, accountDataEvents: accountDataEvents)
        
        XCTAssertEqual(obsoletedEvents, expectedObsoletedEvents)
    }
    
    func testObsoletedDeviceInformation_noMatch() {
        let mxSession = MockSession(canCrossSign: true)
        let dataProvider = UserSessionsDataProvider(session: mxSession)
        
        let accountDataEvents: [String: Any] = [
            "io.element.matrix_client_information.C": "",
            "foo": ""
        ]
        
        let expectedObsoletedEvents: Set<String> = []
        let obsoletedEvents = dataProvider.obsoletedDeviceAccountData(deviceList: .mockDevices, accountDataEvents: accountDataEvents)
        
        XCTAssertEqual(obsoletedEvents, expectedObsoletedEvents)
    }
    
    func testObsoletedDeviceInformation_allMatch() {
        let mxSession = MockSession(canCrossSign: true)
        let dataProvider = UserSessionsDataProvider(session: mxSession)
        
        let expectedObsoletedEvents = Set(["D", "E", "F"].map { "io.element.matrix_client_information.\($0)"})
        
        let accountDataEvents: [String: Any] = expectedObsoletedEvents.reduce(into: ["foo": ""]) { partialResult, value in
            partialResult[value] = ""
        }
        
        let obsoletedEvents = dataProvider.obsoletedDeviceAccountData(deviceList: .mockDevices, accountDataEvents: accountDataEvents)
        
        XCTAssertEqual(obsoletedEvents, expectedObsoletedEvents)
    }
}

// MARK: Mocks

private extension Array where Element == MXDevice {
    static let mockDevices: [MXDevice] = {
        ["A", "B", "C"]
            .map {
                let device = MXDevice()
                device.deviceId = $0
                return device
            }
    }()
}

// Device ID constants.
private extension String {
    static var otherDeviceA: String { "abcdef" }
    static var otherDeviceB: String { "ghijkl" }
    static var currentDevice: String { "uvwxyz" }
}

/// A mock `MXSession` that can override the `canCrossSign` state.
private class MockSession: MXSession {
    let canCrossSign: Bool
    override var myDeviceId: String! { .currentDevice }
    
    override var crypto: MXCrypto! {
        get { MockCrypto(canCrossSign: canCrossSign) }
        set { }
    }
    
    init(canCrossSign: Bool) {
        self.canCrossSign = canCrossSign
        super.init()
    }
    
}

/// A mock `MXCrypto` that can override the `canCrossSign` state.
private class MockCrypto: MXLegacyCrypto {
    let canCrossSign: Bool
    override var crossSigning: MXCrossSigning { MockCrossSigning(canCrossSign: canCrossSign) }
    
    init(canCrossSign: Bool) {
        self.canCrossSign = canCrossSign
        super.init()
    }
    
}

/// A mock `MXCrossSigning` with an overridden `canCrossSign` property.
private class MockCrossSigning: MXLegacyCrossSigning {
    let canCrossSignMock: Bool
    override var canCrossSign: Bool { canCrossSignMock }
    
    init(canCrossSign: Bool) {
        self.canCrossSignMock = canCrossSign
        super.init()
    }
    
    override var state: MXCrossSigningState {
        .crossSigningExists
    }
}

/// A mock `MXDeviceInfo` that can override the `isVerified` state.
private class MockDeviceInfo: MXDeviceInfo {
    private let verified: Bool
    override var trustLevel: MXDeviceTrustLevel! { MockDeviceTrustLevel(verified: verified) }
    
    init(deviceID: String, verified: Bool) {
        self.verified = verified
        super.init(deviceId: deviceID)
    }
    
    required init?(coder: NSCoder) { fatalError() }
}

/// A mock `MXDeviceTrustLevel` with an overridden `isVerified` property.
private class MockDeviceTrustLevel: MXDeviceTrustLevel {
    private let verified: Bool
    override var isVerified: Bool { verified }
    
    init(verified: Bool) {
        self.verified = verified
        super.init()
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
