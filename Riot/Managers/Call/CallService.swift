//
// Copyright 2020 New Vector Ltd
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
import MatrixKit

@objcMembers
/// Service to manage call screens and call bar UI management.
class CallService: NSObject {
    
    private var callVCs: [String: CallViewController] = [:]
    private var callBackgroundTasks: [String: MXBackgroundTask] = [:]
    private weak var presentedCallVC: CallViewController?
    private weak var inBarCallVC: CallViewController?
    private var uiOperationQueue: OperationQueue = .main
    private var isStarted: Bool = false
    private var callTimer: Timer!
    
    private var isCallKitEnabled: Bool {
        MXCallKitAdapter.callKitAvailable() && MXKAppSettings.standard()?.isCallKitEnabled == true
    }
    
    private var activeCallVC: CallViewController? {
        return callVCs.values.filter { (callVC) -> Bool in
            guard let call = callVC.mxCall else {
                return false
            }
            return !call.isOnHold
        }.first
    }
    
    private var numberOfPausedCalls: UInt {
        return UInt(callVCs.values.filter { (callVC) -> Bool in
            guard let call = callVC.mxCall else {
                return false
            }
            return call.isOnHold
        }.count)
    }
    
    //  MARK: - Public
    
    /// Maximum number of concurrent calls allowed.
    let maximumNumberOfConcurrentCalls: UInt = 2
    
    /// Delegate object
    weak var delegate: CallServiceDelegate?
    
    /// Start the service
    func start() {
        addCallObservers()
        startCallTimer()
    }
    
    /// Stop the service
    func stop() {
        removeCallObservers()
        stopCallTimer()
    }
    
    /// Method to be called when the call status bar is tapped.
    /// - Returns: If the user interaction handled or not
    func callStatusBarButtonTapped() -> Bool {
        if let callVC = inBarCallVC ?? activeCallVC {
            dismissCallBar(for: callVC)
            presentCallVC(callVC)
            return true
        }
        return false
    }
    
    //  MARK: - Private
    
    private func shouldHandleCall(_ call: MXCall) -> Bool {
        if let delegate = delegate, !delegate.callService(self, shouldHandleNewCall: call) {
            return false
        }
        return callVCs.count < maximumNumberOfConcurrentCalls
    }
    
    private func endCall(withCallId callId: String) {
        guard let callVC = callVCs[callId] else {
            return
        }
        
        let completion = { [weak self] in
            guard let self = self else {
                return
            }
            self.callVCs.removeValue(forKey: callId)
            callVC.destroy()
            self.callBackgroundTasks[callId]?.stop()
            self.callBackgroundTasks.removeValue(forKey: callId)
            
            //  if still have some calls and there is no present operation in the queue
            if let oldCallVC = self.callVCs.values.first,
               !self.uiOperationQueue.containsPresentCallVCOperation,
               !self.uiOperationQueue.containsPresentCallBarOperation {
                //  present the call bar after dismissing this one
                self.presentCallBar(for: oldCallVC)
            }
        }
        
        if inBarCallVC == callVC {
            //  this call currently in the status bar,
            //  first present it and then dismiss it
            presentCallVC(callVC)
        }
        dismissCallVC(callVC, completion: completion)
    }
    
    //  MARK: - Timer
    
    private func startCallTimer() {
        callTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                                 target: self,
                                                 selector: #selector(callTimerFired(_:)),
                                                 userInfo: nil,
                                                 repeats: true)
    }
    
    private func stopCallTimer() {
        callTimer.invalidate()
        callTimer = nil
    }
    
    @objc private func callTimerFired(_ timer: Timer) {
        guard let inBarCallVC = inBarCallVC else {
            return
        }
        guard let call = inBarCallVC.mxCall else {
            return
        }
        guard call.state != .ended else {
            return
        }
        
        presentCallBar(for: inBarCallVC, isUpdateOnly: true)
    }
    
    //  MARK: - Observers
    
    private func addCallObservers() {
        guard !isStarted else {
            return
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(newCall(_:)),
                                               name: NSNotification.Name(rawValue: kMXCallManagerNewCall),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(callStateChanged(_:)),
                                               name: NSNotification.Name(rawValue: kMXCallStateDidChange),
                                               object: nil)
        
        isStarted = true
    }
    
    private func removeCallObservers() {
        guard isStarted else {
            return
        }
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: kMXCallManagerNewCall),
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: kMXCallStateDidChange),
                                                  object: nil)
        
        isStarted = false
    }
    
    @objc
    private func newCall(_ notification: Notification) {
        guard let call = notification.object as? MXCall else {
            return
        }
        
        if !shouldHandleCall(call) {
            return
        }
        
        guard let newCallVC = CallViewController(call) else {
            return
        }
        newCallVC.playRingtone = !isCallKitEnabled
        newCallVC.delegate = self
        callVCs[call.callId] = newCallVC
        
        if UIApplication.shared.applicationState == .background && call.isIncoming {
            // Create backgound task.
            // Without CallKit this will allow us to play vibro until the call was ended
            // With CallKit we'll inform the system when the call is ended to let the system terminate our app to save resources
            let handler = MXSDKOptions.sharedInstance().backgroundModeHandler
            let callBackgroundTask = handler.startBackgroundTask(withName: "[CallService] addMatrixCallObserver", expirationHandler: nil)
            
            callBackgroundTasks[call.callId] = callBackgroundTask
        }
        
        if call.isIncoming && isCallKitEnabled {
            return
        } else {
            presentCallVC(newCallVC)
        }
    }
    
    @objc
    private func callStateChanged(_ notification: Notification) {
        guard let call = notification.object as? MXCall else {
            return
        }
        
        switch call.state {
        case .createAnswer:
            NSLog("[CallService] callStateChanged: call created answer: \(call.callId)")
            if call.isIncoming, isCallKitEnabled, let callVC = callVCs[call.callId] {
                presentCallVC(callVC)
            }
        case .connected:
            NSLog("[CallService] callStateChanged: call connected: \(call.callId)")
            callTimer.fire()
        case .onHold:
            NSLog("[CallService] callStateChanged: call holded: \(call.callId)")
            callTimer.fire()
        case .remotelyOnHold:
            NSLog("[CallService] callStateChanged: call remotely holded: \(call.callId)")
            callTimer.fire()
        case .ended:
            NSLog("[CallService] callStateChanged: call ended: \(call.callId)")
            endCall(withCallId: call.callId)
        default:
            break
        }
    }
    
    //  MARK: - Call Screens
    
    private func presentCallVC(_ callVC: CallViewController, completion: (() -> Void)? = nil) {
        NSLog("[CallService] presentCallVC: call: \(String(describing: callVC.mxCall?.callId))")
        
        if let inBarCallVC = inBarCallVC {
            dismissCallBar(for: inBarCallVC)
        }
        
        if let presentedCallVC = presentedCallVC {
            dismissCallVC(presentedCallVC)
        }
        
        let operation = CallVCPresentOperation(service: self, callVC: callVC) { [weak self] in
            self?.presentedCallVC = callVC
            completion?()
        }
        uiOperationQueue.addOperation(operation)
    }
    
    private func dismissCallVC(_ callVC: CallViewController, completion: (() -> Void)? = nil) {
        NSLog("[CallService] dismissCallVC: call: \(String(describing: callVC.mxCall?.callId))")
        
        let operation = CallVCDismissOperation(service: self, callVC: callVC) { [weak self] in
            if callVC == self?.presentedCallVC {
                self?.presentedCallVC = nil
            }
            completion?()
        }
        uiOperationQueue.addOperation(operation)
    }
    
    //  MARK: - Call Bar
    
    private func presentCallBar(for callVC: CallViewController?, isUpdateOnly: Bool = false, completion: (() -> Void)? = nil) {
        NSLog("[CallService] presentCallBar: call: \(String(describing: callVC?.mxCall?.callId))")

        let activeCallVC = self.activeCallVC
        
        let operation = CallBarPresentOperation(service: self, activeCallVC: activeCallVC, numberOfPausedCalls: numberOfPausedCalls) { [weak self] in
            //  active calls are more prior to paused ones.
            //  So, if user taps the bar when we have one active and one paused calls, we navigate to the active one.
            if !isUpdateOnly {
                self?.inBarCallVC = activeCallVC ?? callVC
            }
            completion?()
        }
        uiOperationQueue.addOperation(operation)
    }
    
    private func dismissCallBar(for callVC: CallViewController, completion: (() -> Void)? = nil) {
        NSLog("[CallService] dismissCallBar: call: \(String(describing: callVC.mxCall?.callId))")
        
        let operation = CallBarDismissOperation(service: self) { [weak self] in
            if callVC == self?.inBarCallVC {
                self?.inBarCallVC = nil
            }
            completion?()
        }
        
        uiOperationQueue.addOperation(operation)
    }
    
}

//  MARK: - MXKCallViewControllerDelegate

extension CallService: MXKCallViewControllerDelegate {
    
    func dismiss(_ callViewController: MXKCallViewController!, completion: (() -> Void)!) {
        guard let callVC = callViewController as? CallViewController else {
            //  this call screen is not handled by this service
            completion?()
            return
        }
        
        if callVC.mxCall == nil || callVC.mxCall.state == .ended {
            //  wait for the call state changes, will be handled there
            return
        } else {
            dismissCallVC(callVC)
            self.presentCallBar(for: callVC, completion: completion)
        }
    }
    
}

//  MARK: - OperationQueue Extension

extension OperationQueue {
    
    var containsPresentCallVCOperation: Bool {
        return operations.contains { (operation) -> Bool in
            return operation is CallVCPresentOperation
        }
    }
    
    var containsPresentCallBarOperation: Bool {
        return operations.contains { (operation) -> Bool in
            return operation is CallBarPresentOperation
        }
    }
    
}
