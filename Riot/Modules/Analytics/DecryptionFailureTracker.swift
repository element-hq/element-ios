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


// Protocol to get the current time. Used for easy testing
protocol TimeProvider {
    func nowTs() -> TimeInterval
}

class DefaultTimeProvider: TimeProvider {
    
    func nowTs() -> TimeInterval {
        return Date.now.timeIntervalSince1970
    }
    
}


@objc
class DecryptionFailureTracker: NSObject {
    
    let GRACE_PERIOD: TimeInterval = 4
    // Call `checkFailures` every `CHECK_INTERVAL`
    let CHECK_INTERVAL: TimeInterval = 2
    
    @objc weak var delegate: E2EAnalytics?
    
    // Reported failures
    var reportedFailures = [String /* eventId */: DecryptionFailure]()
    
    // Event ids of failures that were tracked previously
    var trackedEvents = Set<String>()
    
    var checkFailuresTimer: Timer?
    
    @objc static let sharedInstance = DecryptionFailureTracker()
    
    var timeProvider: TimeProvider = DefaultTimeProvider()
    
    override init() {
        super.init()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(eventDidDecrypt(_:)),
                                               name: .mxEventDidDecrypt,
                                               object: nil)
        
        Timer.scheduledTimer(withTimeInterval: CHECK_INTERVAL, repeats: true) { [weak self] _ in
            self?.checkFailures()
        }
    }
    
    @objc
    func reportUnableToDecryptError(forEvent event: MXEvent, withRoomState roomState: MXRoomState, myUser userId: String) {
        if reportedFailures[event.eventId] != nil || trackedEvents.contains(event.eventId) {
            return
        }
        
        // Filter out "expected" UTDs
        // We cannot decrypt messages sent before the user joined the room
        guard let myUser = roomState.members.member(withUserId: userId) else { return }
        if myUser.membership != MXMembership.join {
            return
        }

        guard let failedEventId = event.eventId else { return }
        
        guard let error = event.decryptionError as? NSError else { return }
        
        var reason = DecryptionFailureReason.unspecified
        
        if error.code == MXDecryptingErrorUnknownInboundSessionIdCode.rawValue {
            reason = DecryptionFailureReason.olmKeysNotSent
        } else if error.code == MXDecryptingErrorOlmCode.rawValue {
            reason = DecryptionFailureReason.olmIndexError
        }
        
        let context = String(format: "code: %ld, description: %@", error.code, event.decryptionError.localizedDescription)

        reportedFailures[failedEventId] = DecryptionFailure(failedEventId: failedEventId, reason: reason, context: context, ts: self.timeProvider.nowTs())
    }
    
    @objc
    func dispatch() {
        self.checkFailures()
    }
    
    @objc
    func eventDidDecrypt(_ notification: Notification) {
        guard let event = notification.object as? MXEvent else { return }

        // Could be an event in the reportedFailures, remove it
        reportedFailures.removeValue(forKey: event.eventId)
    }
    
    /**
     Mark reported failures that occured before tsNow - GRACE_PERIOD as failures that should be
     tracked.
     */
    @objc
    func checkFailures() {
        guard let delegate = self.delegate else {return}
        
        
        let tsNow = self.timeProvider.nowTs()
        var failuresToCheck = [DecryptionFailure]()
        
        for reportedFailure in self.reportedFailures.values {
            let ellapsed = tsNow - reportedFailure.ts
            if ellapsed > GRACE_PERIOD {
                failuresToCheck.append(reportedFailure)
                reportedFailures.removeValue(forKey: reportedFailure.failedEventId)
                trackedEvents.insert(reportedFailure.failedEventId)
            }
        }
        
        for failure in failuresToCheck {
            delegate.trackE2EEError(failure.reason, context: failure.context)
        }
        
    }
    
}
