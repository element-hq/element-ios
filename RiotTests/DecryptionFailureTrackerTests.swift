// 
// Copyright 2024 New Vector Ltd
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


class DecryptionFailureTrackerTests: XCTestCase {
    
    class TimeShifter: TimeProvider {
        
        var timestamp = TimeInterval(0)
        
        func nowTs() -> TimeInterval {
            return timestamp
        }
    }
    
    class AnalyticsDelegate : E2EAnalytics {
        var reportedFailure: Element.DecryptionFailureReason?;
        
        func trackE2EEError(_ reason: Element.DecryptionFailureReason, context: String) {
            print("Error Tracked: ", reason)
            reportedFailure = reason
        }
        
    }
    
    let timeShifter = TimeShifter()
    
    func test_grace_period() {
        
        let myUser = "test@example.com";
        
        let decryptionFailureTracker = DecryptionFailureTracker();
        decryptionFailureTracker.timeProvider = timeShifter;
        
        let testDelegate = AnalyticsDelegate();
        
        decryptionFailureTracker.delegate = testDelegate;
        
        timeShifter.timestamp = TimeInterval(0)
        
        let fakeEvent = FakeEvent(id: "$0000");
        fakeEvent.decryptionError = NSError(domain: MXDecryptingErrorDomain, code: Int(MXDecryptingErrorUnknownInboundSessionIdCode.rawValue))
        
        
        let fakeRoomState = FakeRoomState();
        fakeRoomState.mockMembers = FakeRoomMembers(joined: [myUser])
        decryptionFailureTracker.reportUnableToDecryptError(forEvent: fakeEvent, withRoomState: fakeRoomState, myUser: myUser);
       
        timeShifter.timestamp = TimeInterval(2)
        
        decryptionFailureTracker.checkFailures();
        
        XCTAssertNil(testDelegate.reportedFailure);
        
        // Pass the grace period
        timeShifter.timestamp = TimeInterval(5)
        
        decryptionFailureTracker.checkFailures();
        
        XCTAssertEqual(testDelegate.reportedFailure, DecryptionFailureReason.olmKeysNotSent);
    }
    
    func test_do_not_double_report() {
        
        let myUser = "test@example.com";
        
        let decryptionFailureTracker = DecryptionFailureTracker();
        decryptionFailureTracker.timeProvider = timeShifter;
        
        let testDelegate = AnalyticsDelegate();
        
        decryptionFailureTracker.delegate = testDelegate;
        
        timeShifter.timestamp = TimeInterval(0)
        
        let fakeEvent = FakeEvent(id: "$0000");
        fakeEvent.decryptionError = NSError(domain: MXDecryptingErrorDomain, code: Int(MXDecryptingErrorUnknownInboundSessionIdCode.rawValue))
        
        
        let fakeRoomState = FakeRoomState();
        fakeRoomState.mockMembers = FakeRoomMembers(joined: [myUser])
        
        decryptionFailureTracker.reportUnableToDecryptError(forEvent: fakeEvent, withRoomState: fakeRoomState, myUser: myUser);
        
        // Pass the grace period
        timeShifter.timestamp = TimeInterval(5)
        
        decryptionFailureTracker.checkFailures();
        
        XCTAssertEqual(testDelegate.reportedFailure, DecryptionFailureReason.olmKeysNotSent);
        
        // Try to report again the same event
        testDelegate.reportedFailure = nil
        decryptionFailureTracker.reportUnableToDecryptError(forEvent: fakeEvent, withRoomState: fakeRoomState, myUser: myUser);
        // Pass the grace period
        timeShifter.timestamp = TimeInterval(10)
        
        decryptionFailureTracker.checkFailures();
        
        XCTAssertNil(testDelegate.reportedFailure);
    }
    
    
    func test_ignore_not_member() {
        
        let myUser = "test@example.com";
        
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
        
        decryptionFailureTracker.reportUnableToDecryptError(forEvent: fakeEvent, withRoomState: fakeRoomState, myUser: myUser);
        
        // Pass the grace period
        timeShifter.timestamp = TimeInterval(5)
        
        decryptionFailureTracker.checkFailures();
      
        XCTAssertNil(testDelegate.reportedFailure);
    }
    
    
    
    func test_notification_center() {
        
        let myUser = "test@example.com";
        
        let decryptionFailureTracker = DecryptionFailureTracker();
        decryptionFailureTracker.timeProvider = timeShifter;
        
        let testDelegate = AnalyticsDelegate();
        
        decryptionFailureTracker.delegate = testDelegate;
        
        timeShifter.timestamp = TimeInterval(0)
        
        let fakeEvent = FakeEvent(id: "$0000");
        fakeEvent.decryptionError = NSError(domain: MXDecryptingErrorDomain, code: Int(MXDecryptingErrorUnknownInboundSessionIdCode.rawValue))
        
        
        let fakeRoomState = FakeRoomState();
        fakeRoomState.mockMembers = FakeRoomMembers(joined: [myUser])
        
        decryptionFailureTracker.reportUnableToDecryptError(forEvent: fakeEvent, withRoomState: fakeRoomState, myUser: myUser);
        
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
    
}
    
