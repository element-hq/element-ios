// 
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

import XCTest
@testable import Element


class DecryptionFailureTrackerTests: XCTestCase {
    
    class TimeShifter: TimeProvider {
        
        var timestamp = TimeInterval(0)
        
        func nowTs() -> TimeInterval {
            return timestamp
        }
    }
    
    class AnalyticsDelegate : E2EAnalytics {
        var reportedFailure: Element.DecryptionFailure?;
        
        func trackE2EEError(_ reason: Element.DecryptionFailure) {
            reportedFailure = reason
        }
        
    }
    
    let timeShifter = TimeShifter()
    var fakeCrypto: FakeCrypto!
    var fakeSession: FakeSession!
    var fakeCrossSigning: FakeCrossSigning!
    
    override func setUp() {
        super.setUp()
        self.fakeCrypto = FakeCrypto()
        self.fakeCrossSigning = FakeCrossSigning()
        self.fakeCrypto.crossSigning = self.fakeCrossSigning
        self.fakeSession = FakeSession(mockCrypto: self.fakeCrypto)
    }
    
    
    func test_grace_period() {
        
        let myUser = "@test:example.com";
        fakeSession.mockUserId = myUser;
        
        let decryptionFailureTracker = DecryptionFailureTracker();
        decryptionFailureTracker.timeProvider = timeShifter;
        
        let testDelegate = AnalyticsDelegate();
        
        decryptionFailureTracker.delegate = testDelegate;
        
        timeShifter.timestamp = TimeInterval(0)
        
        let fakeEvent = FakeEvent(id: "$0000");
        fakeEvent.decryptionError = NSError(domain: MXDecryptingErrorDomain, code: Int(MXDecryptingErrorUnknownInboundSessionIdCode.rawValue))
        
        
        let fakeRoomState = FakeRoomState();
        fakeRoomState.mockMembers = FakeRoomMembers(joined: [myUser])
        decryptionFailureTracker.reportUnableToDecryptError(forEvent: fakeEvent, withRoomState: fakeRoomState, mySession: fakeSession);
       
        timeShifter.timestamp = TimeInterval(2)
        
        // simulate decrypted in the grace period
        NotificationCenter.default.post(name: .mxEventDidDecrypt, object: fakeEvent)
        
        decryptionFailureTracker.checkFailures();
        
        XCTAssertNil(testDelegate.reportedFailure);
        
        // Pass the grace period
        timeShifter.timestamp = TimeInterval(5)
        
        decryptionFailureTracker.checkFailures();
        XCTAssertNil(testDelegate.reportedFailure);
        
    }
    
    func test_report_ratcheted_key_utd() {
        
        let myUser = "@test:example.com";
        fakeSession.mockUserId = myUser;
        
        let decryptionFailureTracker = DecryptionFailureTracker();
        decryptionFailureTracker.timeProvider = timeShifter;
        
        let testDelegate = AnalyticsDelegate();
        
        decryptionFailureTracker.delegate = testDelegate;
        
        timeShifter.timestamp = TimeInterval(0)
        
        let fakeEvent = FakeEvent(id: "$0000");
        fakeEvent.decryptionError = NSError(domain: MXDecryptingErrorDomain, code: Int(MXDecryptingErrorOlmCode.rawValue))
        
        
        let fakeRoomState = FakeRoomState();
        fakeRoomState.mockMembers = FakeRoomMembers(joined: [myUser])
        decryptionFailureTracker.reportUnableToDecryptError(forEvent: fakeEvent, withRoomState: fakeRoomState, mySession: fakeSession);
        
        // Pass the max period
        timeShifter.timestamp = TimeInterval(70)
        
        decryptionFailureTracker.checkFailures();
        
        XCTAssertEqual(testDelegate.reportedFailure?.reason, DecryptionFailureReason.olmIndexError);
    }
    
    func test_report_unspecified_error() {
        
        let myUser = "@test:example.com";
        fakeSession.mockUserId = myUser;
        
        let decryptionFailureTracker = DecryptionFailureTracker();
        decryptionFailureTracker.timeProvider = timeShifter;
        
        let testDelegate = AnalyticsDelegate();
        
        decryptionFailureTracker.delegate = testDelegate;
        
        timeShifter.timestamp = TimeInterval(0)
        
        let fakeEvent = FakeEvent(id: "$0000");
        fakeEvent.decryptionError = NSError(domain: MXDecryptingErrorDomain, code: Int(MXDecryptingErrorBadRoomCode.rawValue))
        
        
        let fakeRoomState = FakeRoomState();
        fakeRoomState.mockMembers = FakeRoomMembers(joined: [myUser])
        decryptionFailureTracker.reportUnableToDecryptError(forEvent: fakeEvent, withRoomState: fakeRoomState, mySession: fakeSession);
        
        // Pass the max period
        timeShifter.timestamp = TimeInterval(70)
        
        decryptionFailureTracker.checkFailures();
        
        XCTAssertEqual(testDelegate.reportedFailure?.reason, DecryptionFailureReason.unspecified);
    }
    
    
    
    func test_do_not_double_report() {
        
        let myUser = "@test:example.com";
        fakeSession.mockUserId = myUser;
        
        let decryptionFailureTracker = DecryptionFailureTracker();
        decryptionFailureTracker.timeProvider = timeShifter;
        
        let testDelegate = AnalyticsDelegate();
        
        decryptionFailureTracker.delegate = testDelegate;
        
        timeShifter.timestamp = TimeInterval(0)
        
        let fakeEvent = FakeEvent(id: "$0000");
        fakeEvent.decryptionError = NSError(domain: MXDecryptingErrorDomain, code: Int(MXDecryptingErrorUnknownInboundSessionIdCode.rawValue))
        
        
        let fakeRoomState = FakeRoomState();
        fakeRoomState.mockMembers = FakeRoomMembers(joined: [myUser])
        
        decryptionFailureTracker.reportUnableToDecryptError(forEvent: fakeEvent, withRoomState: fakeRoomState, mySession: fakeSession);
        
        // Pass the max period
        timeShifter.timestamp = TimeInterval(70)
        
        decryptionFailureTracker.checkFailures();
        
        XCTAssertEqual(testDelegate.reportedFailure?.reason, DecryptionFailureReason.olmKeysNotSent);
        
        // Try to report again the same event
        testDelegate.reportedFailure = nil
        decryptionFailureTracker.reportUnableToDecryptError(forEvent: fakeEvent, withRoomState: fakeRoomState, mySession: fakeSession);
        // Pass the grace period
        timeShifter.timestamp = TimeInterval(10)
        
        decryptionFailureTracker.checkFailures();
        
        XCTAssertNil(testDelegate.reportedFailure);
    }
    
    
    func test_ignore_not_member() {
        
        let myUser = "@test:example.com";
        fakeSession.mockUserId = myUser;
        
        let decryptionFailureTracker = DecryptionFailureTracker();
        decryptionFailureTracker.timeProvider = timeShifter;
        
        let testDelegate = AnalyticsDelegate();
        
        decryptionFailureTracker.delegate = testDelegate;
        
        timeShifter.timestamp = TimeInterval(0)
        
        let fakeEvent = FakeEvent(id: "$0000");
        fakeEvent.decryptionError = NSError(domain: MXDecryptingErrorDomain, code: Int(MXDecryptingErrorUnknownInboundSessionIdCode.rawValue))
        
        
        let fakeRoomState = FakeRoomState();
        let fakeMembers = FakeRoomMembers()
        fakeMembers.mockMembers[myUser] = MXMembership.ban
        fakeRoomState.mockMembers = fakeMembers
        
        decryptionFailureTracker.reportUnableToDecryptError(forEvent: fakeEvent, withRoomState: fakeRoomState, mySession: fakeSession);
        
        // Pass the grace period
        timeShifter.timestamp = TimeInterval(5)
        
        decryptionFailureTracker.checkFailures();
      
        XCTAssertNil(testDelegate.reportedFailure);
    }
    
    
    
    func test_notification_center() {
        
        let myUser = "@test:example.com";
        fakeSession.mockUserId = myUser;
        
        let decryptionFailureTracker = DecryptionFailureTracker();
        decryptionFailureTracker.timeProvider = timeShifter;
        
        let testDelegate = AnalyticsDelegate();
        
        decryptionFailureTracker.delegate = testDelegate;
        
        timeShifter.timestamp = TimeInterval(0)
        
        let fakeEvent = FakeEvent(id: "$0000");
        fakeEvent.decryptionError = NSError(domain: MXDecryptingErrorDomain, code: Int(MXDecryptingErrorUnknownInboundSessionIdCode.rawValue))
        
        
        let fakeRoomState = FakeRoomState();
        fakeRoomState.mockMembers = FakeRoomMembers(joined: [myUser])
        
        decryptionFailureTracker.reportUnableToDecryptError(forEvent: fakeEvent, withRoomState: fakeRoomState, mySession: fakeSession);
        
        // Shift time below GRACE_PERIOD
        timeShifter.timestamp = TimeInterval(2)
        
        // Simulate event gets decrypted
        NotificationCenter.default.post(name: .mxEventDidDecrypt, object: fakeEvent)
        
        
        // Shift time after GRACE_PERIOD
        timeShifter.timestamp = TimeInterval(6)
        
        
        decryptionFailureTracker.checkFailures();
      
        // Event should have been graced
        XCTAssertNil(testDelegate.reportedFailure);
    }
    
    
    func test_should_report_late_decrypt() {
        
        let myUser = "@test:example.com";
        fakeSession.mockUserId = myUser;
        
        let decryptionFailureTracker = DecryptionFailureTracker();
        decryptionFailureTracker.timeProvider = timeShifter;
        
        let testDelegate = AnalyticsDelegate();
        
        decryptionFailureTracker.delegate = testDelegate;
        
        timeShifter.timestamp = TimeInterval(0)
        
        let fakeEvent = FakeEvent(id: "$0000");
        fakeEvent.decryptionError = NSError(domain: MXDecryptingErrorDomain, code: Int(MXDecryptingErrorUnknownInboundSessionIdCode.rawValue))
        
        
        let fakeRoomState = FakeRoomState();
        fakeRoomState.mockMembers = FakeRoomMembers(joined: [myUser])
        
        decryptionFailureTracker.reportUnableToDecryptError(forEvent: fakeEvent, withRoomState: fakeRoomState, mySession: fakeSession);
        
        // Simulate succesful decryption after grace period but before max wait
        timeShifter.timestamp = TimeInterval(20)
        
        // Simulate event gets decrypted
        NotificationCenter.default.post(name: .mxEventDidDecrypt, object: fakeEvent)
        
        
        decryptionFailureTracker.checkFailures();
      
        // Event should have been reported as a late decrypt
        XCTAssertEqual(testDelegate.reportedFailure?.reason, DecryptionFailureReason.olmKeysNotSent);
        XCTAssertEqual(testDelegate.reportedFailure?.timeToDecrypt, TimeInterval(20));
        
        // Assert that it's converted to millis for reporting
        let analyticsError = testDelegate.reportedFailure!.toAnalyticsEvent()
        
        XCTAssertEqual(analyticsError.timeToDecryptMillis, 20000)
        
    }
    
    
    
    func test_should_report_permanent_decryption_error() {
        
        let myUser = "@test:example.com";
        fakeSession.mockUserId = myUser;
        
        let decryptionFailureTracker = DecryptionFailureTracker();
        decryptionFailureTracker.timeProvider = timeShifter;
        
        let testDelegate = AnalyticsDelegate();
        
        decryptionFailureTracker.delegate = testDelegate;
        
        timeShifter.timestamp = TimeInterval(0)
        
        let fakeEvent = FakeEvent(id: "$0000");
        fakeEvent.decryptionError = NSError(domain: MXDecryptingErrorDomain, code: Int(MXDecryptingErrorUnknownInboundSessionIdCode.rawValue))
        
        
        let fakeRoomState = FakeRoomState();
        fakeRoomState.mockMembers = FakeRoomMembers(joined: [myUser])
        
        decryptionFailureTracker.reportUnableToDecryptError(forEvent: fakeEvent, withRoomState: fakeRoomState, mySession: fakeSession);
        
        // Simulate succesful decryption after max wait
        timeShifter.timestamp = TimeInterval(70)
        
        decryptionFailureTracker.checkFailures();
      
        // Event should have been reported as a late decrypt
        XCTAssertEqual(testDelegate.reportedFailure?.reason, DecryptionFailureReason.olmKeysNotSent);
        XCTAssertNil(testDelegate.reportedFailure?.timeToDecrypt);
        
        
        // Assert that it's converted to -1 for reporting
        let analyticsError = testDelegate.reportedFailure!.toAnalyticsEvent()
        
        XCTAssertEqual(analyticsError.timeToDecryptMillis, -1)
        
    }
    
    
    func test_should_report_trust_status_at_decryption_time() {
        
        let myUser = "@test:example.com";
        fakeSession.mockUserId = myUser;
        
        let decryptionFailureTracker = DecryptionFailureTracker();
        decryptionFailureTracker.timeProvider = timeShifter;
        
        let testDelegate = AnalyticsDelegate();
        
        decryptionFailureTracker.delegate = testDelegate;
        
        timeShifter.timestamp = TimeInterval(0)
        
        let fakeEvent = FakeEvent(id: "$0000");
        fakeEvent.decryptionError = NSError(domain: MXDecryptingErrorDomain, code: Int(MXDecryptingErrorUnknownInboundSessionIdCode.rawValue))
        
        // set session as not yet verified
        fakeCrossSigning.canTrustCrossSigning = false
        
        let fakeRoomState = FakeRoomState();
        fakeRoomState.mockMembers = FakeRoomMembers(joined: [myUser])
        
        decryptionFailureTracker.reportUnableToDecryptError(forEvent: fakeEvent, withRoomState: fakeRoomState, mySession: fakeSession);
        
        // set verified now
        fakeCrossSigning.canTrustCrossSigning = true
        
        // Simulate succesful decryption after max wait
        timeShifter.timestamp = TimeInterval(70)
        
        decryptionFailureTracker.checkFailures();
      
        // Event should have been reported as a late decrypt
        XCTAssertEqual(testDelegate.reportedFailure?.trustOwnIdentityAtTimeOfFailure, false);
        
        // Assert that it's converted to -1 for reporting
        let analyticsError = testDelegate.reportedFailure!.toAnalyticsEvent()
        
        XCTAssertEqual(analyticsError.userTrustsOwnIdentity, false)
        
        // Report a new error now that session is verified
        
        let fakeEvent2 = FakeEvent(id: "$0001");
        fakeEvent2.decryptionError = NSError(domain: MXDecryptingErrorDomain, code: Int(MXDecryptingErrorUnknownInboundSessionIdCode.rawValue))
        
        
        decryptionFailureTracker.reportUnableToDecryptError(forEvent: fakeEvent2, withRoomState: fakeRoomState, mySession: fakeSession);
        
        // Simulate permanent UTD
        timeShifter.timestamp = TimeInterval(140)
        
        decryptionFailureTracker.checkFailures();
      
        XCTAssertEqual(testDelegate.reportedFailure?.failedEventId, "$0001");
        XCTAssertEqual(testDelegate.reportedFailure?.trustOwnIdentityAtTimeOfFailure, true);
        
        let analyticsError2 = testDelegate.reportedFailure!.toAnalyticsEvent()
        
        XCTAssertEqual(analyticsError2.userTrustsOwnIdentity, true)
        
    }
    
    
    func test_should_report_event_age() {
        
        let myUser = "@test:example.com";
        fakeSession.mockUserId = myUser;
        
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        let sessionCreationTimeMillis = format.date(from: "2024-03-09T10:00:00Z")!.timeIntervalSince1970 * 1000
        
        let now = format.date(from: "2024-03-09T10:02:00Z")!.timeIntervalSince1970
        
        // 5mn after session was created
        let postCreationMessageTs = UInt64(format.date(from: "2024-03-09T10:05:00Z")!.timeIntervalSince1970 * 1000)
        
        let decryptionFailureTracker = DecryptionFailureTracker();
        decryptionFailureTracker.timeProvider = timeShifter;
        
        let testDelegate = AnalyticsDelegate();
        
        decryptionFailureTracker.delegate = testDelegate;
        
        timeShifter.timestamp = now
        
        let fakeEvent = FakeEvent(id: "$0000");
        fakeEvent.mockOrigineServerTs = postCreationMessageTs;
        fakeEvent.decryptionError = NSError(domain: MXDecryptingErrorDomain, code: Int(MXDecryptingErrorUnknownInboundSessionIdCode.rawValue))
        
        fakeCrypto.deviceCreationTs = UInt64(sessionCreationTimeMillis)
        
        let fakeRoomState = FakeRoomState();
        fakeRoomState.mockMembers = FakeRoomMembers(joined: [myUser])
        
        decryptionFailureTracker.reportUnableToDecryptError(forEvent: fakeEvent, withRoomState: fakeRoomState, mySession: fakeSession);
        
        // set verified now
        fakeCrossSigning.canTrustCrossSigning = true
        
        // Simulate permanent UTD
        timeShifter.timestamp = now + TimeInterval(70)
        
        decryptionFailureTracker.checkFailures();
      
        XCTAssertEqual(testDelegate.reportedFailure?.eventLocalAgeMillis, 5 * 60 * 1000);
        
        let analyticsError = testDelegate.reportedFailure!.toAnalyticsEvent()
        
        XCTAssertEqual(analyticsError.eventLocalAgeMillis, 5 * 60 * 1000)
        
    }
    
    
    func test_should_report_expected_utds() {
        
        let myUser = "@test:example.com";
        fakeSession.mockUserId = myUser;
        
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        let sessionCreationTimeMillis = format.date(from: "2024-03-09T10:00:00Z")!.timeIntervalSince1970 * 1000
        
        let now = format.date(from: "2024-03-09T10:02:00Z")!.timeIntervalSince1970
        
        // 1 day before session was created
        let historicalMessageTs = UInt64(format.date(from: "2024-03-08T10:00:00Z")!.timeIntervalSince1970 * 1000)
        
        let decryptionFailureTracker = DecryptionFailureTracker();
        decryptionFailureTracker.timeProvider = timeShifter;
        
        let testDelegate = AnalyticsDelegate();
        
        decryptionFailureTracker.delegate = testDelegate;
        
        timeShifter.timestamp = now
        
        let fakeEvent = FakeEvent(id: "$0000");
        fakeEvent.mockOrigineServerTs = historicalMessageTs;
        fakeEvent.decryptionError = NSError(domain: MXDecryptingErrorDomain, code: Int(MXDecryptingErrorUnknownInboundSessionIdCode.rawValue))
        
        fakeCrypto.deviceCreationTs = UInt64(sessionCreationTimeMillis)
        
        let fakeRoomState = FakeRoomState();
        fakeRoomState.mockMembers = FakeRoomMembers(joined: [myUser])
        
        fakeCrossSigning.canTrustCrossSigning = false
        
        decryptionFailureTracker.reportUnableToDecryptError(forEvent: fakeEvent, withRoomState: fakeRoomState, mySession: fakeSession);
        
        // set verified now
        fakeCrossSigning.canTrustCrossSigning = true
        
        // Simulate permanent UTD
        timeShifter.timestamp = now + TimeInterval(70)
        
        decryptionFailureTracker.checkFailures();
      
        // Event should have been reported as a late decrypt
        XCTAssertEqual(testDelegate.reportedFailure?.eventLocalAgeMillis, -24 * 60 * 60 * 1000);
        
        let analyticsError = testDelegate.reportedFailure!.toAnalyticsEvent()
        
        XCTAssertEqual(analyticsError.name, .HistoricalMessage)
        
    }
    
    
    func test_should_report_is_matrix_org_and_is_federated() {
        
        let myUser = "@test:example.com";
        fakeSession.mockUserId = myUser;
        
        let decryptionFailureTracker = DecryptionFailureTracker();
        decryptionFailureTracker.timeProvider = timeShifter;
        
        let testDelegate = AnalyticsDelegate();
        
        decryptionFailureTracker.delegate = testDelegate;
        
        timeShifter.timestamp = TimeInterval(0)
        
        let fakeEvent = FakeEvent(id: "$0000");
        fakeEvent.sender = "@bob:example.com"
        fakeEvent.decryptionError = NSError(domain: MXDecryptingErrorDomain, code: Int(MXDecryptingErrorUnknownInboundSessionIdCode.rawValue))
        
        // set session as not yet verified
        fakeCrossSigning.canTrustCrossSigning = false
        
        let fakeRoomState = FakeRoomState();
        fakeRoomState.mockMembers = FakeRoomMembers(joined: [myUser])
        
        decryptionFailureTracker.reportUnableToDecryptError(forEvent: fakeEvent, withRoomState: fakeRoomState, mySession: fakeSession);
        
        // Simulate succesful decryption after max wait
        timeShifter.timestamp = TimeInterval(70)
        
        decryptionFailureTracker.checkFailures();
      
        XCTAssertEqual(testDelegate.reportedFailure?.isMatrixOrg, false);
        XCTAssertEqual(testDelegate.reportedFailure?.isFederated, false);

        
        let analyticsError = testDelegate.reportedFailure!.toAnalyticsEvent()
        
        XCTAssertEqual(analyticsError.isMatrixDotOrg, false)
        XCTAssertEqual(analyticsError.isFederated, false)
        
        // Report a new error now that session is verified
        
        let fakeEvent2 = FakeEvent(id: "$0001");
        fakeEvent2.sender = "@bob:example.com"
        fakeEvent2.decryptionError = NSError(domain: MXDecryptingErrorDomain, code: Int(MXDecryptingErrorUnknownInboundSessionIdCode.rawValue))
        
        fakeSession.mockUserId = "@test:matrix.org";
        fakeRoomState.mockMembers = FakeRoomMembers(joined: [fakeSession.mockUserId])
    
        decryptionFailureTracker.reportUnableToDecryptError(forEvent: fakeEvent2, withRoomState: fakeRoomState, mySession: fakeSession);
        
        // Simulate permanent UTD
        timeShifter.timestamp = TimeInterval(140)
        
        decryptionFailureTracker.checkFailures();
      
        XCTAssertEqual(testDelegate.reportedFailure?.failedEventId, "$0001");
        XCTAssertEqual(testDelegate.reportedFailure?.isMatrixOrg, true);
        XCTAssertEqual(testDelegate.reportedFailure?.isFederated, true);
        
        let analyticsError2 = testDelegate.reportedFailure!.toAnalyticsEvent()
        
        XCTAssertEqual(analyticsError2.isMatrixDotOrg, true)
        XCTAssertEqual(analyticsError2.isFederated, true)
        
    }
    
    
}
    
