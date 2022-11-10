// 
// Copyright 2022 New Vector Ltd
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

import XCTest
@testable import Element
@testable import MatrixSDK

private let currentDeviceId = "deviceId"
private let unverifiedDeviceId = "unverifiedDeviceId"
private let currentUserId = "userId"

class UserSessionsOverviewServiceTests: XCTestCase {
    func testInitialSessionUnverified() {
        let dataProvider = MockUserSessionsDataProvider(mode: .currentSessionUnverified)
        let service = UserSessionsOverviewService(dataProvider: dataProvider)
        
        XCTAssertNotNil(service.currentSession)
        XCTAssertEqual(service.currentSession?.verificationState, .unverified)
        XCTAssertTrue(service.currentSession?.isActive ?? false)
        XCTAssertFalse(service.unverifiedSessions.isEmpty)
        XCTAssertTrue(service.inactiveSessions.isEmpty)
        XCTAssertFalse(service.linkDeviceEnabled)
        
        XCTAssertEqual(service.sessionForIdentifier(currentDeviceId), service.currentSession)
    }
    
    func testInitialSessionVerified() {
        let dataProvider = MockUserSessionsDataProvider(mode: .currentSessionVerified)
        let service = UserSessionsOverviewService(dataProvider: dataProvider)
        
        XCTAssertNotNil(service.currentSession)
        XCTAssertEqual(service.currentSession?.verificationState, .verified)
        XCTAssertTrue(service.currentSession?.isActive ?? false)
        XCTAssertTrue(service.unverifiedSessions.isEmpty)
        XCTAssertTrue(service.inactiveSessions.isEmpty)
        XCTAssertFalse(service.linkDeviceEnabled)
    }
    
    func testWithAllSessionsVerified() {
        let service = setupServiceWithMode(.allOtherSessionsValid)
        
        XCTAssertNotNil(service.currentSession)
        XCTAssertEqual(service.currentSession?.verificationState, .verified)
        XCTAssertTrue(service.currentSession?.isActive ?? false)
        
        XCTAssertTrue(service.unverifiedSessions.isEmpty)
        XCTAssertTrue(service.inactiveSessions.isEmpty)
        XCTAssertFalse(service.otherSessions.isEmpty)
        XCTAssertTrue(service.linkDeviceEnabled)
    }
    
    func testWithSomeUnverifiedSessions() {
        let service = setupServiceWithMode(.someUnverifiedSessions)
        
        XCTAssertNotNil(service.currentSession)
        XCTAssertEqual(service.currentSession?.verificationState, .verified)
        XCTAssertTrue(service.currentSession?.isActive ?? false)
        
        XCTAssertFalse(service.unverifiedSessions.isEmpty)
        XCTAssertTrue(service.inactiveSessions.isEmpty)
        XCTAssertFalse(service.otherSessions.isEmpty)
        XCTAssertTrue(service.linkDeviceEnabled)
    }
    
    func testWithSomeInactiveSessions() {
        let service = setupServiceWithMode(.someInactiveSessions)
        
        XCTAssertNotNil(service.currentSession)
        XCTAssertEqual(service.currentSession?.verificationState, .verified)
        XCTAssertTrue(service.currentSession?.isActive ?? false)
        
        XCTAssertTrue(service.unverifiedSessions.isEmpty)
        XCTAssertFalse(service.inactiveSessions.isEmpty)
        XCTAssertFalse(service.otherSessions.isEmpty)
        XCTAssertTrue(service.linkDeviceEnabled)
    }
    
    func testWithSomeUnverifiedAndInactiveSessions() {
        let service = setupServiceWithMode(.someUnverifiedAndInactiveSessions)
        
        XCTAssertNotNil(service.currentSession)
        XCTAssertEqual(service.currentSession?.verificationState, .verified)
        XCTAssertTrue(service.currentSession?.isActive ?? false)
        
        XCTAssertFalse(service.unverifiedSessions.isEmpty)
        XCTAssertFalse(service.inactiveSessions.isEmpty)
        XCTAssertFalse(service.otherSessions.isEmpty)
        XCTAssertTrue(service.linkDeviceEnabled)
    }
    
    // MARK: - Private
    
    private func setupServiceWithMode(_ mode: MockUserSessionsDataProvider.Mode) -> UserSessionsOverviewServiceProtocol {
        let dataProvider = MockUserSessionsDataProvider(mode: mode)
        let service = UserSessionsOverviewService(dataProvider: dataProvider)
        
        let expectation = expectation(description: "Wait for service update")
        service.updateOverviewData { _ in
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
        
        return service
    }
}

private extension UserSessionsOverviewServiceProtocol {
    var unverifiedSessions: [UserSessionInfo] { overviewDataPublisher.value.unverifiedSessions }
    var inactiveSessions: [UserSessionInfo] { overviewDataPublisher.value.inactiveSessions }
    var linkDeviceEnabled: Bool { overviewDataPublisher.value.linkDeviceEnabled }
}

private class MockUserSessionsDataProvider: UserSessionsDataProviderProtocol {
    enum Mode {
        case currentSessionUnverified
        case currentSessionVerified
        case allOtherSessionsValid
        case someUnverifiedSessions
        case someInactiveSessions
        case someUnverifiedAndInactiveSessions
    }
    
    private let mode: Mode
    
    var myDeviceId = currentDeviceId
    
    var myUserId: String? = currentUserId
    
    var activeAccounts: [MXKAccount] {
        [MockAccount()]
    }
    
    init(mode: Mode) {
        self.mode = mode
    }
    
    func devices(completion: @escaping (MXResponse<[MXDevice]>) -> Void) {
        DispatchQueue.main.async {
            switch self.mode {
            case .currentSessionUnverified:
                return
            case .currentSessionVerified:
                return
            case .allOtherSessionsValid:
                completion(.success(self.verifiedSessions))
            case .someUnverifiedSessions:
                completion(.success(self.verifiedSessions + self.unverifiedSessions))
            case .someInactiveSessions:
                completion(.success(self.verifiedSessions + self.inactiveSessions))
            case .someUnverifiedAndInactiveSessions:
                completion(.success(self.verifiedSessions + self.unverifiedSessions + self.inactiveSessions))
            }
        }
    }
    
    func device(withDeviceId deviceId: String, ofUser userId: String) -> MXDeviceInfo? {
        guard deviceId == currentDeviceId else {
            return MockDeviceInfo(deviceID: deviceId,
                                  verified: deviceId != unverifiedDeviceId)
        }
        
        switch mode {
        case .currentSessionUnverified:
            return MockDeviceInfo(deviceID: deviceId, verified: false)
        default:
            return MockDeviceInfo(deviceID: deviceId, verified: true)
        }
    }
    
    func verificationState(for deviceInfo: MXDeviceInfo?) -> UserSessionInfo.VerificationState {
        guard let deviceInfo = deviceInfo else { return .unknown }
        
        if let currentSession = device(withDeviceId: currentDeviceId, ofUser: currentUserId),
           !currentSession.trustLevel.isVerified {
            // When the current session is unverified we can't determine verification for other sessions.
            return deviceInfo.deviceId == currentDeviceId ? .unverified : .unknown
        }
        
        return deviceInfo.trustLevel.isVerified ? .verified : .unverified
    }
    
    func accountData(for eventType: String) -> [AnyHashable : Any]? {
        [:]
    }

    func qrLoginAvailable() async throws -> Bool {
        true
    }
    
    // MARK: - Private
    
    var verifiedSessions: [MXDevice] {
        [MockDevice(identifier: currentDeviceId, sessionActive: true),
         MockDevice(identifier: UUID().uuidString, sessionActive: true)]
    }
    
    var unverifiedSessions: [MXDevice] {
        [MockDevice(identifier: unverifiedDeviceId, sessionActive: true)]
    }
    
    var inactiveSessions: [MXDevice] {
        [MockDevice(identifier: UUID().uuidString, sessionActive: false)]
    }
}

private class MockAccount: MXKAccount {
    override var device: MXDevice? {
        MockDevice(identifier: currentDeviceId, sessionActive: true)
    }
}

private class MockDevice: MXDevice {
    private let identifier: String
    private let sessionActive: Bool
    
    init(identifier: String, sessionActive: Bool) {
        self.identifier = identifier
        self.sessionActive = sessionActive
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override var deviceId: String {
        get {
            identifier
        }
        set {
            
        }
    }
    
    override var lastSeenTs: UInt64 {
        get {
            if sessionActive {
                return UInt64(Date().timeIntervalSince1970 * 1000)
            } else {
                let ninetyDays: Double = 90 * 86400
                return UInt64((Date().timeIntervalSince1970 - ninetyDays) * 1000)
            }
        }
        set {
            
        }
    }
}

private class MockDeviceInfo: MXDeviceInfo {
    private let verified: Bool
    
    init(deviceID: String, verified: Bool) {
        self.verified = verified
        super.init(deviceId: deviceID)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override var trustLevel: MXDeviceTrustLevel! {
        MockDeviceTrustLevel(verified: verified)
    }
}

private class MockDeviceTrustLevel: MXDeviceTrustLevel {
    private let verified: Bool
    
    init(verified: Bool) {
        self.verified = verified
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override var isVerified: Bool {
        verified
    }
}
