//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import PostHog
@testable import Element


class FakeEvent: MXEvent {
    
    var mockEventId: String;
    var mockSender: String!;
    var mockDecryptionError: Error?
    var mockOrigineServerTs: UInt64 = 0
    
    init(id: String) {
        mockEventId = id
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override var sender: String! {
        get { return mockSender }
        set { mockSender = newValue }
    }
    
    override var eventId: String! {
        get { return mockEventId }
        set { mockEventId = newValue }
    }
    
    override var decryptionError: Error? {
        get { return mockDecryptionError }
        set { mockDecryptionError = newValue }
    }
    
    override var originServerTs: UInt64 {
        get { return mockOrigineServerTs }
        set { mockOrigineServerTs = newValue }
        
    }
    
}


class FakeRoomState: MXRoomState {
    
    var mockMembers: MXRoomMembers?
    
    override var members: MXRoomMembers? {
        get { return mockMembers }
        set { mockMembers = newValue }
    }
    
}

class FakeRoomMember: MXRoomMember {
    var mockMembership: MXMembership = MXMembership.join
    var mockUserId: String!
    var mockMembers: MXRoomMembers? = FakeRoomMembers()
    
    init(mockUserId: String!) {
        self.mockUserId = mockUserId
        super.init()
    }
    
    override var membership: MXMembership {
        get { return mockMembership }
        set { mockMembership = newValue }
    }
    
    override var userId: String!{
        get { return mockUserId }
        set { mockUserId = newValue }
    }
    
}


class FakeRoomMembers: MXRoomMembers {
    
    var mockMembers = [String : MXMembership]()
    
    init(joined: [String] = [String]()) {
        for userId in joined {
            self.mockMembers[userId] = MXMembership.join
        }
        super.init()
    }
    
    override func member(withUserId userId: String!) -> MXRoomMember? {
        let membership = mockMembers[userId]
        if membership != nil {
            let mockMember = FakeRoomMember(mockUserId: userId)
            mockMember.mockMembership = membership!
            return mockMember
        } else {
            return nil
        }
    }
    
}

class FakeSession: MXSession {
    
    var mockCrypto: MXCrypto? = FakeCrypto()
    
    var mockUserId: String = "@alice:localhost"
    
    init(mockCrypto: MXCrypto? = nil) {
        self.mockCrypto = mockCrypto
        super.init()
    }
    
    override var crypto: MXCrypto? {
        get {
            return mockCrypto
        }
        set {
            // nothing
        }
    }
    
    override var myUserId: String! {
        get {
            return mockUserId
        }
        set {
            mockUserId = newValue
        }
    }
}

class FakeCrypto: NSObject, MXCrypto {
    
    
    var version: String = ""
    
    var deviceCurve25519Key: String?
    
    var deviceEd25519Key: String?
    
    var deviceCreationTs: UInt64 = 0
    
    var backup: MXKeyBackup?
    
    var keyVerificationManager: MXKeyVerificationManager = FakeKeyVerificationManager()
    
    var crossSigning: MXCrossSigning = FakeCrossSigning()
    
    var recoveryService: MXRecoveryService! = nil
    
    var dehydrationService: MatrixSDK.DehydrationService! = nil
    
    override init() {
        super.init()
    }
    
    func start(_ onComplete: (() -> Void)?, failure: ((Swift.Error) -> Void)? = nil) {
        
    }
    
    func close(_ deleteStore: Bool) {
        
    }
    
    func isRoomEncrypted(_ roomId: String) -> Bool {
        return true
    }
    
    func encryptEventContent(_ eventContent: [AnyHashable : Any], withType eventType: String, in room: MXRoom, success: (([AnyHashable : Any], String) -> Void)?, failure: ((Swift.Error) -> Void)? = nil) -> MXHTTPOperation? {
        return nil
    }
    
    func decryptEvents(_ events: [MXEvent], inTimeline timeline: String?, onComplete: (([MXEventDecryptionResult]) -> Void)? = nil) {
        
    }
    
    func ensureEncryption(inRoom roomId: String, success: (() -> Void)?, failure: ((Swift.Error) -> Void)? = nil) -> MXHTTPOperation? {
        return nil
    }
    
    func eventDeviceInfo(_ event: MXEvent) -> MXDeviceInfo? {
        return nil
    }
    
    func discardOutboundGroupSessionForRoom(withRoomId roomId: String, onComplete: (() -> Void)? = nil) {
        
    }
    
    func handle(_ syncResponse: MXSyncResponse, onComplete: @escaping () -> Void) {
        
    }
    
    func setDeviceVerification(_ verificationStatus: MXDeviceVerification, forDevice deviceId: String, ofUser userId: String, success: (() -> Void)?, failure: ((Swift.Error) -> Void)? = nil) {
        
    }
    
    func setUserVerification(_ verificationStatus: Bool, forUser userId: String, success: (() -> Void)?, failure: ((Swift.Error) -> Void)? = nil) {
        
    }
    
    func trustLevel(forUser userId: String) -> MXUserTrustLevel {
        return MXUserTrustLevel.init(crossSigningVerified: true, locallyVerified: true)
    }
    
    func deviceTrustLevel(forDevice deviceId: String, ofUser userId: String) -> MXDeviceTrustLevel? {
        return nil
    }
    
    func trustLevelSummary(forUserIds userIds: [String], forceDownload: Bool, success: ((MXUsersTrustLevelSummary?) -> Void)?, failure: ((Swift.Error) -> Void)? = nil) {
        
    }
    
    func downloadKeys(_ userIds: [String], forceDownload: Bool, success: ((MXUsersDevicesMap<MXDeviceInfo>?, [String : MXCrossSigningInfo]?) -> Void)?, failure: ((Swift.Error) -> Void)? = nil) -> MXHTTPOperation? {
        return nil
    }
    
    func devices(forUser userId: String) -> [String : MXDeviceInfo] {
        return [:];
    }
    
    func device(withDeviceId deviceId: String, ofUser userId: String) -> MXDeviceInfo? {
        return nil
    }
    
    func exportRoomKeys(withPassword password: String, success: ((Data) -> Void)?, failure: ((Swift.Error) -> Void)? = nil) {
        
    }
    
    func importRoomKeys(_ keyFile: Data, withPassword password: String, success: ((UInt, UInt) -> Void)?, failure: ((Swift.Error) -> Void)? = nil) {
        
    }
    
    func reRequestRoomKey(for event: MXEvent) {
        
    }
    
    var globalBlacklistUnverifiedDevices: Bool = false
    
    func isBlacklistUnverifiedDevices(inRoom roomId: String) -> Bool {
        return false
    }
    
    func setBlacklistUnverifiedDevicesInRoom(_ roomId: String, blacklist: Bool) {
        
    }
    
    func invalidateCache(_ done: @escaping () -> Void) {
        
    }
}


class FakeCrossSigning: NSObject, MXCrossSigning {
    
    
    override init() {
        super.init()
    }
    
    var state: MXCrossSigningState = MXCrossSigningState.trustCrossSigning
    
    var myUserCrossSigningKeys: MXCrossSigningInfo? = nil
    
    var canTrustCrossSigning: Bool = true
    
    var canCrossSign: Bool = true
    
    var hasAllPrivateKeys: Bool = true
    
    func refreshState(success: ((Bool) -> Void)?, failure: ((Swift.Error) -> Void)? = nil) {
        
    }
    
    func setup(withPassword password: String, success: @escaping () -> Void, failure: @escaping (Swift.Error) -> Void) {
        
    }
    
    func setup(withAuthParams authParams: [AnyHashable : Any], success: @escaping () -> Void, failure: @escaping (Swift.Error) -> Void) {
        
    }
    
    func crossSignDevice(withDeviceId deviceId: String, userId: String, success: @escaping () -> Void, failure: @escaping (Swift.Error) -> Void) {
        
    }
    
    func signUser(withUserId userId: String, success: @escaping () -> Void, failure: @escaping (Swift.Error) -> Void) {
        
    }
    
    func crossSigningKeys(forUser userId: String) -> MXCrossSigningInfo? {
        return nil
    }
    
}

class FakeKeyVerificationManager: NSObject, MXKeyVerificationManager {
    
    override init() {
        super.init()
    }
    
    func requestVerificationByToDevice(withUserId userId: String, deviceIds: [String]?, methods: [String], success: @escaping (MXKeyVerificationRequest) -> Void, failure: @escaping (Swift.Error) -> Void) {
        
    }
    
    func requestVerificationByDM(withUserId userId: String, roomId: String?, fallbackText: String, methods: [String], success: @escaping (MXKeyVerificationRequest) -> Void, failure: @escaping (Swift.Error) -> Void) {
        
    }
    
    var pendingRequests: [MXKeyVerificationRequest] = []
    
    func beginKeyVerification(from request: MXKeyVerificationRequest, method: String, success: @escaping (MXKeyVerificationTransaction) -> Void, failure: @escaping (Swift.Error) -> Void) {
        
    }
    
    func transactions(_ complete: @escaping ([MXKeyVerificationTransaction]) -> Void) {
        
    }
    
    func keyVerification(fromKeyVerificationEvent event: MXEvent, roomId: String, success: @escaping (MXKeyVerification) -> Void, failure: @escaping (Swift.Error) -> Void) -> MXHTTPOperation? {
        return nil
    }
    
    func qrCodeTransaction(withTransactionId transactionId: String) -> MXQRCodeTransaction? {
        return nil
    }
    
    func removeQRCodeTransaction(withTransactionId transactionId: String) {
        
    }
    
}

class MockPostHog: PostHogProtocol {
    
    private var enabled = false
    
    func optIn() {
        enabled = true
    }
    
    func optOut() {
        enabled = false
    }
    
    func reset() { }
    
    func flush() {
        
    }
    
    var capturePropertiesUserPropertiesUnderlyingCallsCount = 0
    var capturePropertiesUserPropertiesCallsCount: Int {
        get {
            if Thread.isMainThread {
                return capturePropertiesUserPropertiesUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = capturePropertiesUserPropertiesUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                capturePropertiesUserPropertiesUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    capturePropertiesUserPropertiesUnderlyingCallsCount = newValue
                }
            }
        }
    }
    var capturePropertiesUserPropertiesCalled: Bool {
        return capturePropertiesUserPropertiesCallsCount > 0
    }
    var capturePropertiesUserPropertiesReceivedArguments: (event: String, properties: [String: Any]?, userProperties: [String: Any]?)?
    var capturePropertiesUserPropertiesReceivedInvocations: [(event: String, properties: [String: Any]?, userProperties: [String: Any]?)] = []
    var capturePropertiesUserPropertiesClosure: ((String, [String: Any]?, [String: Any]?) -> Void)?

    func capture(_ event: String, properties: [String: Any]?, userProperties: [String: Any]?) {
        if !enabled { return }
        capturePropertiesUserPropertiesCallsCount += 1
        capturePropertiesUserPropertiesReceivedArguments = (event: event, properties: properties, userProperties: userProperties)
        capturePropertiesUserPropertiesReceivedInvocations.append((event: event, properties: properties, userProperties: userProperties))
        capturePropertiesUserPropertiesClosure?(event, properties, userProperties)
    }
    
    var screenPropertiesUnderlyingCallsCount = 0
    var screenPropertiesCallsCount: Int {
        get {
            if Thread.isMainThread {
                return screenPropertiesUnderlyingCallsCount
            } else {
                var returnValue: Int? = nil
                DispatchQueue.main.sync {
                    returnValue = screenPropertiesUnderlyingCallsCount
                }

                return returnValue!
            }
        }
        set {
            if Thread.isMainThread {
                screenPropertiesUnderlyingCallsCount = newValue
            } else {
                DispatchQueue.main.sync {
                    screenPropertiesUnderlyingCallsCount = newValue
                }
            }
        }
    }
    
    var screenPropertiesCalled: Bool {
        return screenPropertiesCallsCount > 0
    }
    var screenPropertiesReceivedArguments: (screenTitle: String, properties: [String: Any]?)?
    var screenPropertiesReceivedInvocations: [(screenTitle: String, properties: [String: Any]?)] = []
    var screenPropertiesClosure: ((String, [String: Any]?) -> Void)?

    func screen(_ screenTitle: String, properties: [String: Any]?) {
        if !enabled { return }
        screenPropertiesCallsCount += 1
        screenPropertiesReceivedArguments = (screenTitle: screenTitle, properties: properties)
        screenPropertiesReceivedInvocations.append((screenTitle: screenTitle, properties: properties))
        screenPropertiesClosure?(screenTitle, properties)
    }
    
    func isFeatureEnabled(_ feature: String) -> Bool {
        return true
    }
    
    func identify(_ distinctId: String) {
        
    }
    
    func identify(_ distinctId: String, userProperties: [String : Any]?) {
        
    }
    
    func isOptOut() -> Bool {
        !enabled
    }
    
    
}

class MockPostHogFactory: PostHogFactory {
    var mock: PostHogProtocol!
    
    init(mock: PostHogProtocol) {
        self.mock = mock
    }
    
    func createPostHog(config: PostHogConfig) -> PostHogProtocol {
        mock
    }
}

