// 
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
    let CHECK_INTERVAL: TimeInterval = 15
    
    // The maximum time to wait for a late decryption before reporting as permanent UTD
    let MAX_WAIT_FOR_LATE_DECRYPTION: TimeInterval = 60
    
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
    }
    
    @objc
    func reportUnableToDecryptError(forEvent event: MXEvent, withRoomState roomState: MXRoomState, mySession: MXSession) {
        if reportedFailures[event.eventId] != nil || trackedEvents.contains(event.eventId) {
            return
        }
        guard let userId = mySession.myUserId else { return }
        
        // Filter out "expected" UTDs
        // We cannot decrypt messages sent before the user joined the room
        guard let myUser = roomState.members.member(withUserId: userId) else { return }
        if myUser.membership != MXMembership.join {
            return
        }

        guard let failedEventId = event.eventId else { return }
        
        guard let error = event.decryptionError as? NSError else { return }
        
        let eventOrigin = event.originServerTs
        let deviceTimestamp = mySession.crypto.deviceCreationTs
        // If negative it's an historical event relative to the current session
        let eventRelativeAgeMillis = Int(eventOrigin) - Int(deviceTimestamp)
        let isSessionVerified = mySession.crypto.crossSigning.canTrustCrossSigning
        
        var reason = DecryptionFailureReason.unspecified
        
        if error.code == MXDecryptingErrorUnknownInboundSessionIdCode.rawValue {
            reason = DecryptionFailureReason.olmKeysNotSent
        } else if error.code == MXDecryptingErrorOlmCode.rawValue {
            reason = DecryptionFailureReason.olmIndexError
        }
        
        let context = String(format: "code: %ld, description: %@", error.code, event.decryptionError.localizedDescription)

        let failure = DecryptionFailure(failedEventId: failedEventId, reason: reason, context: context, ts: self.timeProvider.nowTs())
        
        failure.eventLocalAgeMillis = Int(exactly: eventRelativeAgeMillis)
        failure.trustOwnIdentityAtTimeOfFailure = isSessionVerified
        
        let myDomain = userId.components(separatedBy: ":").last
        failure.isMatrixOrg = myDomain == "matrix.org"
        
        if MXTools.isMatrixUserIdentifier(event.sender) {
            let senderDomain = event.sender.components(separatedBy: ":").last
            failure.isFederated = senderDomain != nil && senderDomain != myDomain
        }
        
        /// XXX for future work, as for now only the event formatter reports UTDs. That means that it's only UTD ~visible to users
        failure.wasVisibleToUser = true
        
        reportedFailures[failedEventId] = failure
        
        
        // Start the ticker if needed. There is no need to have a ticker if no failures are tracked
        if checkFailuresTimer == nil {
            self.checkFailuresTimer = Timer.scheduledTimer(withTimeInterval: CHECK_INTERVAL, repeats: true) { [weak self] _ in
                self?.checkFailures()
            }
        }
        
    }
    
    @objc
    func dispatch() {
        self.checkFailures()
    }
    
    @objc
    func eventDidDecrypt(_ notification: Notification) {
        guard let event = notification.object as? MXEvent else { return }

        guard let reportedFailure = self.reportedFailures[event.eventId] else { return }
        
        let now = self.timeProvider.nowTs()
        let ellapsedTime = now - reportedFailure.ts
        
        if ellapsedTime < 4 {
            // event is graced
            reportedFailures.removeValue(forKey: event.eventId)
        } else {
            // It's a late decrypt must be reported as a late decrypt
            reportedFailure.timeToDecrypt = ellapsedTime
            self.delegate?.trackE2EEError(reportedFailure)
        }
        // Remove from reported failures
        self.trackedEvents.insert(event.eventId)
        reportedFailures.removeValue(forKey: event.eventId)
        
        // Check if we still need the ticker timer
        if reportedFailures.isEmpty {
            // Invalidate the current timer, nothing to check for
            self.checkFailuresTimer?.invalidate()
            self.checkFailuresTimer = nil
        }
        
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
            if ellapsed > MAX_WAIT_FOR_LATE_DECRYPTION {
                failuresToCheck.append(reportedFailure)
                reportedFailure.timeToDecrypt = nil
                reportedFailures.removeValue(forKey: reportedFailure.failedEventId)
                trackedEvents.insert(reportedFailure.failedEventId)
            }
        }
        
        for failure in failuresToCheck {
            delegate.trackE2EEError(failure)
        }
        
        // Check if we still need the ticker timer
        if reportedFailures.isEmpty {
            // Invalidate the current timer, nothing to check for
            self.checkFailuresTimer?.invalidate()
            self.checkFailuresTimer = nil
        }
    }
    
}
