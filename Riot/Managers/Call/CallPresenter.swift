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

// swiftlint:disable file_length

#if canImport(JitsiMeetSDK)
import JitsiMeetSDK
import CallKit
#endif

/// The number of milliseconds in one second.
private let MSEC_PER_SEC: TimeInterval = 1000

@objcMembers
/// Service to manage call screens and call bar UI management.
class CallPresenter: NSObject {
    
    private enum Constants {
        static let pipAnimationDuration: TimeInterval = 0.25
        static let groupCallInviteLifetime: TimeInterval = 30
    }
    
    private var sessions: [MXSession] = []
    private var callVCs: [String: CallViewController] = [:]
    private var callBackgroundTasks: [String: MXBackgroundTask] = [:]
    private weak var presentedCallVC: CallViewController? {
        didSet {
            updateOnHoldCall()
        }
    }
    private weak var presentedGroupCallVC: JitsiViewController? {
        didSet {
            updateOnHoldCall()
        }
    }
    private weak var inBarCallVC: UIViewController?
    private weak var pipCallVC: CallViewController?
    private weak var pipGroupCallVC: JitsiViewController?
    private var uiOperationQueue: OperationQueue = .main
    private var isStarted: Bool = false
    private var callTimer: Timer?
    #if canImport(JitsiMeetSDK)
    private var widgetEventsListener: Any?
    /// Jitsi calls map. Keys are CallKit call UUIDs, values are corresponding widgets.
    private var jitsiCalls: [UUID: Widget] = [:]
    /// The current Jitsi view controller being displayed.
    private(set) var jitsiVC: JitsiViewController?
    #endif
    
    private var isCallKitEnabled: Bool {
        MXCallKitAdapter.callKitAvailable() && MXKAppSettings.standard()?.isCallKitEnabled == true
    }
    
    private var activeCallVC: UIViewController? {
        return callVCs.values.filter { (callVC) -> Bool in
            guard let call = callVC.mxCall else {
                return false
            }
            return !call.isOnHold
        }.first ?? jitsiVC
    }
    
    private var onHoldCallVCs: [CallViewController] {
        return callVCs.values.filter { (callVC) -> Bool in
            guard let call = callVC.mxCall else {
                return false
            }
            return call.isOnHold
        }
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
    weak var delegate: CallPresenterDelegate?
    
    func addMatrixSession(_ session: MXSession) {
        sessions.append(session)
    }
    
    func removeMatrixSession(_ session: MXSession) {
        if let index = sessions.firstIndex(of: session) {
            sessions.remove(at: index)
        }
    }
    
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
    func callStatusBarTapped() {
        if let callVC = (inBarCallVC ?? activeCallVC) as? CallViewController {
            dismissCallBar(for: callVC)
            presentCallVC(callVC)
            return
        }
        if let jitsiVC = jitsiVC {
            dismissCallBar(for: jitsiVC)
            presentGroupCallVC(jitsiVC)
        }
    }
    
    //  MARK - Group Calls
    
    /// Open the Jitsi view controller from a widget.
    /// - Parameter widget: the jitsi widget
    func displayJitsiCall(withWidget widget: Widget) {
        #if canImport(JitsiMeetSDK)
        if jitsiVC == nil {
            jitsiVC = JitsiViewController()
            jitsiVC?.openWidget(widget, withVideo: true, success: { [weak self] in
                guard let self = self else { return }
                if let jitsiVC = self.jitsiVC {
                    jitsiVC.delegate = self
                    self.presentGroupCallVC(jitsiVC)
                    self.startJitsiCall(withWidget: widget)
                }
            }, failure: { [weak self] (error) in
                guard let self = self else { return }
                self.jitsiVC = nil
                AppDelegate.theDelegate().showAlert(withTitle: nil,
                                                    message: VectorL10n.callJitsiError)
            })
        } else {
            AppDelegate.theDelegate().showAlert(withTitle: nil, message:
                                                    VectorL10n.callAlreadyDisplayed)
        }
        #else
        AppDelegate.theDelegate().showAlert(withTitle: nil,
                                            message: Bundle.mxk_localizedString(forKey: "not_supported_yet"))
        #endif
    }
    
    private func startJitsiCall(withWidget widget: Widget) {
        if self.jitsiCalls.first(where: { $0.value.widgetId == widget.widgetId })?.key != nil {
            //  this Jitsi call is already managed by this class, no need to report the call again
            return
        }
        
        guard let roomId = widget.roomId else {
            return
        }
        
        guard let session = sessions.first else {
            return
        }
        
        guard let room = session.room(withRoomId: roomId) else {
            return
        }
        
        let newUUID = UUID()
        let handle = CXHandle(type: .generic, value: roomId)
        let startCallAction = CXStartCallAction(call: newUUID, handle: handle)
        let transaction = CXTransaction(action: startCallAction)
        JMCallKitProxy.request(transaction) { (error) in
            if error == nil {
                JMCallKitProxy.reportCallUpdate(with: newUUID,
                                                handle: roomId,
                                                displayName: room.summary.displayname,
                                                hasVideo: true)
                JMCallKitProxy.reportOutgoingCall(with: newUUID, connectedAt: nil)

                self.jitsiCalls[newUUID] = widget
            }
        }
    }
    
    func endActiveJitsiCall() {
        guard let widget = jitsiVC?.widget else {
            //  there is no active Jitsi call
            return
        }
        guard let uuid = self.jitsiCalls.first(where: { $0.value.widgetId == widget.widgetId })?.key else {
            //  this Jitsi call is not managed by this class
            return
        }
        
        if let inBarCallVC = inBarCallVC {
            dismissCallBar(for: inBarCallVC)
        }
        
        if let jitsiVC = jitsiVC {
            dismissGroupCallVC(jitsiVC)
            jitsiVC.hangup()
        }
        
        jitsiVC = nil
        
        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)
        JMCallKitProxy.request(transaction) { (error) in
            if error == nil {
                self.jitsiCalls.removeValue(forKey: uuid)
            }
        }
    }
    
    func processWidgetEvent(_ event: MXEvent, inSession session: MXSession) {
        guard JMCallKitProxy.isProviderConfigured() else {
            //  CallKit proxy is not configured, no benefit in parsing the event
            return
        }
        
        guard let widget = Widget(widgetEvent: event, inMatrixSession: session) else {
            return
        }
        
        if self.jitsiCalls.first(where: { $0.value.widgetId == widget.widgetId })?.key != nil {
            //  this Jitsi call is already managed by this class, no need to report the call again
            return
        }
        
        if widget.isActive {
            guard widget.type == kWidgetTypeJitsiV1 || widget.type == kWidgetTypeJitsiV2 else {
                //  not a Jitsi widget, ignore
                return
            }
            
            if let jitsiVC = jitsiVC,
               jitsiVC.widget.widgetId == widget.widgetId {
                //  this is already the Jitsi call we have atm
                return
            }
            
            if TimeInterval(event.age)/MSEC_PER_SEC > Constants.groupCallInviteLifetime {
                //  too late to process the event
                return
            }
            
            //  an active Jitsi widget
            let newUUID = UUID()
            
            //  assume this Jitsi call will survive
            self.jitsiCalls[newUUID] = widget
            
            if event.sender == session.myUserId {
                //  outgoing call
                JMCallKitProxy.reportOutgoingCall(with: newUUID, connectedAt: nil)
            } else {
                //  incoming call
                let user = session.user(withUserId: event.sender)
                let displayName = NSString.localizedUserNotificationString(forKey: "GROUP_CALL_FROM_USER",
                                                                           arguments: [user?.displayname as Any])
                JMCallKitProxy.reportNewIncomingCall(UUID: newUUID,
                                                     handle: widget.roomId,
                                                     displayName: displayName,
                                                     hasVideo: true) { (error) in
                    if error != nil {
                        self.jitsiCalls.removeValue(forKey: newUUID)
                    }
                }
            }
        } else {
            guard let uuid = self.jitsiCalls.first(where: { $0.value.widgetId == widget.widgetId })?.key else {
                //  this Jitsi call is not managed by this class
                return
            }
            JMCallKitProxy.reportCall(with: uuid, endedAt: nil, reason: .remoteEnded)
            self.jitsiCalls.removeValue(forKey: uuid)
        }
    }
    
    //  MARK: - Private
    
    private func updateOnHoldCall() {
        guard let presentedCallVC = presentedCallVC else {
            return
        }
        
        if onHoldCallVCs.isEmpty {
            //  no on hold calls, clear the call
            presentedCallVC.mxCallOnHold = nil
        } else {
            for callVC in onHoldCallVCs where callVC != presentedCallVC {
                //  do not set the same call (can happen in case of two on hold calls)
                presentedCallVC.mxCallOnHold = callVC.mxCall
                break
            }
        }
    }
    
    private func shouldHandleCall(_ call: MXCall) -> Bool {
        return callVCs.count < maximumNumberOfConcurrentCalls
    }
    
    private func callHolded(withCallId callId: String) {
        updateOnHoldCall()
    }
    
    private func endCall(withCallId callId: String) {
        guard let callVC = callVCs[callId] else {
            return
        }
        
        let completion = { [weak self] in
            guard let self = self else {
                return
            }
            
            self.updateOnHoldCall()
            
            self.callVCs.removeValue(forKey: callId)
            callVC.destroy()
            self.callBackgroundTasks[callId]?.stop()
            self.callBackgroundTasks.removeValue(forKey: callId)
            
            //  if still have some calls and there is no present operation in the queue
            if let oldCallVC = self.callVCs.values.first,
               self.presentedCallVC == nil,
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
        if pipCallVC == callVC {
            //  this call currently in the PiP mode,
            //  first present it by exiting PiP mode and then dismiss it
            exitPipCallVC(callVC) {
                self.dismissCallVC(callVC, completion: completion)
            }
            return
        }
        if callVC.isDisplayingAlert {
            completion()
        } else {
            dismissCallVC(callVC, completion: completion)
        }
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
        callTimer?.invalidate()
        callTimer = nil
    }
    
    @objc private func callTimerFired(_ timer: Timer) {
        guard let inBarCallVC = inBarCallVC as? CallViewController else {
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
        
        defer {
            isStarted = true
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(newCall(_:)),
                                               name: NSNotification.Name(rawValue: kMXCallManagerNewCall),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(callStateChanged(_:)),
                                               name: NSNotification.Name(rawValue: kMXCallStateDidChange),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(callTileTapped(_:)),
                                               name: .RoomCallTileTapped,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(groupCallTileTapped(_:)),
                                               name: .RoomGroupCallTileTapped,
                                               object: nil)
        
        #if canImport(JitsiMeetSDK)
        JMCallKitProxy.addListener(self)
        
        guard let session = sessions.first else {
            return
        }
        
        widgetEventsListener = session.listenToEvents([
            MXEventType(identifier: kWidgetMatrixEventTypeString),
            MXEventType(identifier: kWidgetModularEventTypeString)
        ]) { (event, direction, _) in
            if direction == .backwards {
                //  ignore backwards events
                return
            }
            
            self.processWidgetEvent(event, inSession: session)
        }
        #endif
    }
    
    private func removeCallObservers() {
        guard isStarted else {
            return
        }
        
        defer {
            isStarted = false
        }
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: kMXCallManagerNewCall),
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: kMXCallStateDidChange),
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: .RoomCallTileTapped,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: .RoomGroupCallTileTapped,
                                                  object: nil)
        
        #if canImport(JitsiMeetSDK)
        JMCallKitProxy.removeListener(self)
        
        guard let session = sessions.first else {
            return
        }
        
        if let widgetEventsListener = widgetEventsListener {
            session.removeListener(widgetEventsListener)
        }
        widgetEventsListener = nil
        #endif
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
            callTimer?.fire()
        case .onHold:
            NSLog("[CallService] callStateChanged: call holded: \(call.callId)")
            callTimer?.fire()
            callHolded(withCallId: call.callId)
        case .remotelyOnHold:
            NSLog("[CallService] callStateChanged: call remotely holded: \(call.callId)")
            callTimer?.fire()
            callHolded(withCallId: call.callId)
        case .ended:
            NSLog("[CallService] callStateChanged: call ended: \(call.callId)")
            endCall(withCallId: call.callId)
        default:
            break
        }
    }
    
    @objc
    private func callTileTapped(_ notification: Notification) {
        NSLog("[CallService] callTileTapped")
        
        guard let bubbleData = notification.object as? RoomBubbleCellData else {
            return
        }
        
        guard let randomEvent = bubbleData.allLinkedEvents().randomElement() else {
            return
        }
        
        guard let callEventContent = MXCallEventContent(fromJSON: randomEvent.content) else {
            return
        }
        
        NSLog("[CallService] callTileTapped: for call: \(callEventContent.callId)")
        
        guard let session = sessions.first else { return }
        
        guard let call = session.callManager.call(withCallId: callEventContent.callId) else {
            return
        }
        
        if call.state == .ended {
            return
        }
        
        guard let callVC = callVCs[call.callId] else {
            return
        }
        
        presentCallVC(callVC)
    }
    
    @objc
    private func groupCallTileTapped(_ notification: Notification) {
        NSLog("[CallService] groupCallTileTapped")
        
        guard let bubbleData = notification.object as? RoomBubbleCellData else {
            return
        }
        
        guard let randomEvent = bubbleData.allLinkedEvents().randomElement() else {
            return
        }
        
        guard randomEvent.eventType == .custom,
                (randomEvent.type == kWidgetMatrixEventTypeString ||
                    randomEvent.type == kWidgetModularEventTypeString) else {
            return
        }
        
        guard let session = sessions.first else { return }
        
        guard let widget = Widget(widgetEvent: randomEvent, inMatrixSession: session) else {
            return
        }
        
        NSLog("[CallService] groupCallTileTapped: for call: \(widget.widgetId)")
        
        guard let jitsiVC = jitsiVC,
              jitsiVC.widget.widgetId == widget.widgetId else {
            return
        }
        
        presentGroupCallVC(jitsiVC)
    }
    
    //  MARK: - Call Screens
    
    private func presentCallVC(_ callVC: CallViewController, completion: (() -> Void)? = nil) {
        NSLog("[CallService] presentCallVC: call: \(String(describing: callVC.mxCall?.callId))")
        
        //  do not use PiP transitions here, as we really want to present the screen
        callVC.transitioningDelegate = nil
        
        if let inBarCallVC = inBarCallVC {
            dismissCallBar(for: inBarCallVC)
        }
        
        if let presentedCallVC = presentedCallVC {
            dismissCallVC(presentedCallVC)
        }
        
        let operation = CallVCPresentOperation(presenter: self, callVC: callVC) { [weak self] in
            self?.presentedCallVC = callVC
            if callVC == self?.pipCallVC {
                self?.pipCallVC = nil
            }
            completion?()
        }
        uiOperationQueue.addOperation(operation)
    }
    
    private func dismissCallVC(_ callVC: CallViewController, completion: (() -> Void)? = nil) {
        NSLog("[CallService] dismissCallVC: call: \(String(describing: callVC.mxCall?.callId))")
        
        //  do not use PiP transitions here, as we really want to dismiss the screen
        callVC.transitioningDelegate = nil
        
        let operation = CallVCDismissOperation(presenter: self, callVC: callVC) { [weak self] in
            if callVC == self?.presentedCallVC {
                self?.presentedCallVC = nil
            }
            completion?()
        }
        uiOperationQueue.addOperation(operation)
    }
    
    private func enterPipCallVC(_ callVC: CallViewController, completion: (() -> Void)? = nil) {
        NSLog("[CallService] enterPipCallVC: call: \(String(describing: callVC.mxCall?.callId))")
        
        //  assign self as transitioning delegate
        callVC.transitioningDelegate = self
        
        let operation = CallVCEnterPipOperation(presenter: self, callVC: callVC) { [weak self] in
            self?.pipCallVC = callVC
            if callVC == self?.presentedCallVC {
                self?.presentedCallVC = nil
            }
            completion?()
        }
        uiOperationQueue.addOperation(operation)
    }
    
    private func exitPipCallVC(_ callVC: CallViewController, completion: (() -> Void)? = nil) {
        NSLog("[CallService] exitPipCallVC: call: \(String(describing: callVC.mxCall?.callId))")
        
        //  assign self as transitioning delegate
        callVC.transitioningDelegate = self
        
        let operation = CallVCExitPipOperation(presenter: self, callVC: callVC) { [weak self] in
            if callVC == self?.pipCallVC {
                self?.pipCallVC = nil
            }
            self?.presentedCallVC = callVC
            completion?()
        }
        uiOperationQueue.addOperation(operation)
    }
    
    //  MARK: - Call Bar
    
    private func presentCallBar(for callVC: UIViewController?, isUpdateOnly: Bool = false, completion: (() -> Void)? = nil) {
        if let callVC = callVC as? CallViewController {
            NSLog("[CallService] presentCallBar: call: \(String(describing: callVC.mxCall?.callId))")
        } else if let callVC = callVC as? JitsiViewController {
            NSLog("[CallService] presentCallBar: call: \(callVC.widget.widgetId)")
        }

        let activeCallVC = self.activeCallVC
        
        let operation = CallBarPresentOperation(presenter: self, activeCallVC: activeCallVC, numberOfPausedCalls: numberOfPausedCalls) { [weak self] in
            //  active calls are more prior to paused ones.
            //  So, if user taps the bar when we have one active and one paused call, we navigate to the active one.
            if !isUpdateOnly {
                self?.inBarCallVC = activeCallVC ?? callVC
            }
            completion?()
        }
        uiOperationQueue.addOperation(operation)
    }
    
    private func dismissCallBar(for callVC: UIViewController, completion: (() -> Void)? = nil) {
        if let callVC = callVC as? CallViewController {
            NSLog("[CallService] dismissCallBar: call: \(String(describing: callVC.mxCall?.callId))")
        } else if let callVC = callVC as? JitsiViewController {
            NSLog("[CallService] dismissCallBar: call: \(callVC.widget.widgetId)")
        }
        
        let operation = CallBarDismissOperation(presenter: self) { [weak self] in
            if callVC == self?.inBarCallVC {
                self?.inBarCallVC = nil
            }
            completion?()
        }
        
        uiOperationQueue.addOperation(operation)
    }
    
    //  MARK - Group Calls
    
    private func presentGroupCallVC(_ callVC: JitsiViewController, completion: (() -> Void)? = nil) {
        NSLog("[CallService] presentGroupCallVC: call: \(callVC.widget.widgetId)")
        
        //  do not use PiP transitions here, as we really want to present the screen
        callVC.transitioningDelegate = nil
        
        if let inBarCallVC = inBarCallVC {
            dismissCallBar(for: inBarCallVC)
        }
        
        if let presentedCallVC = presentedCallVC {
            dismissCallVC(presentedCallVC)
        }
        
        let operation = GroupCallVCPresentOperation(presenter: self, callVC: callVC) { [weak self] in
            self?.presentedGroupCallVC = callVC
            if callVC == self?.pipGroupCallVC {
                self?.pipGroupCallVC = nil
            }
            completion?()
        }
        uiOperationQueue.addOperation(operation)
    }
    
    private func dismissGroupCallVC(_ callVC: JitsiViewController, completion: (() -> Void)? = nil) {
        NSLog("[CallService] dismissGroupCallVC: call: \(callVC.widget.widgetId)")
        
        //  do not use PiP transitions here, as we really want to dismiss the screen
        callVC.transitioningDelegate = nil
        
        let operation = GroupCallVCDismissOperation(presenter: self, callVC: callVC) { [weak self] in
            if callVC == self?.presentedGroupCallVC {
                self?.presentedGroupCallVC = nil
            }
            completion?()
        }
        uiOperationQueue.addOperation(operation)
    }
    
}

//  MARK: - MXKCallViewControllerDelegate

extension CallPresenter: MXKCallViewControllerDelegate {
    
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
            if callVC.mxCall.isVideoCall {
                //  go to pip mode here
                enterPipCallVC(callVC, completion: completion)
            } else {
                dismissCallVC(callVC)
                self.presentCallBar(for: callVC, completion: completion)
            }
        }
    }
    
    func callViewControllerDidTap(onHoldCall callViewController: MXKCallViewController!) {
        guard let callOnHold = callViewController.mxCallOnHold else {
            return
        }
        guard let onHoldCallVC = callVCs[callOnHold.callId] else {
            return
        }
        
        if callOnHold.state == .onHold {
            //  call is on hold locally, switch calls
            callViewController.mxCall.hold(true)
            callOnHold.hold(false)
        }
        
        //  switch screens
        presentCallVC(onHoldCallVC)
    }
    
}

//  MARK: - UIViewControllerTransitioningDelegate

extension CallPresenter: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PiPAnimator(animationDuration: Constants.pipAnimationDuration,
                           animationType: .exit,
                           pipViewDelegate: nil)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PiPAnimator(animationDuration: Constants.pipAnimationDuration,
                           animationType: .enter,
                           pipViewDelegate: self)
    }
    
}

//  MARK: - PiPViewDelegate

extension CallPresenter: PiPViewDelegate {
    
    func pipViewDidTap(_ view: PiPView) {
        guard let pipCallVC = pipCallVC else { return }
        
        exitPipCallVC(pipCallVC)
    }
    
}

//  MARK: - OperationQueue Extension

extension OperationQueue {
    
    var containsPresentCallVCOperation: Bool {
        return containsOperation(ofType: CallVCPresentOperation.self)
    }
    
    var containsPresentCallBarOperation: Bool {
        return containsOperation(ofType: CallBarPresentOperation.self)
    }
    
    private func containsOperation(ofType type: Operation.Type) -> Bool {
        return operations.contains { (operation) -> Bool in
            return operation.isKind(of: type.self)
        }
    }
    
}

#if canImport(JitsiMeetSDK)
//  MARK: - JMCallKitListener

extension CallPresenter: JMCallKitListener {
    
    func providerDidReset() {
        
    }
    
    func performAnswerCall(UUID: UUID) {
        guard let widget = jitsiCalls[UUID] else {
            return
        }
        
        displayJitsiCall(withWidget: widget)
    }
    
    func performEndCall(UUID: UUID) {
        guard let widget = jitsiCalls[UUID] else {
            return
        }
        
        if let jitsiVC = jitsiVC, jitsiVC.widget.widgetId == widget.widgetId {
            //  hangup an active call
            dismissGroupCallVC(jitsiVC)
            endActiveJitsiCall()
        } else {
            //  decline incoming call
            JitsiService.shared.declineWidget(withId: widget.widgetId)
        }
    }
    
    func performSetMutedCall(UUID: UUID, isMuted: Bool) {
        guard let widget = jitsiCalls[UUID] else {
            return
        }
        
        if let jitsiVC = jitsiVC, jitsiVC.widget.widgetId == widget.widgetId {
            //  mute the active Jitsi call
            jitsiVC.setAudioMuted(isMuted)
        }
    }
    
    func performStartCall(UUID: UUID, isVideo: Bool) {
        
    }
    
    func providerDidActivateAudioSession(session: AVAudioSession) {
        
    }

    func providerDidDeactivateAudioSession(session: AVAudioSession) {
        
    }

    func providerTimedOutPerformingAction(action: CXAction) {
        
    }
    
}

//  MARK - JitsiViewControllerDelegate

extension CallPresenter: JitsiViewControllerDelegate {
    
    func jitsiViewController(_ jitsiViewController: JitsiViewController!, dismissViewJitsiController completion: (() -> Void)!) {
        if jitsiViewController == jitsiVC {
            endActiveJitsiCall()
        }
    }
    
    func jitsiViewController(_ jitsiViewController: JitsiViewController!, goBackToApp completion: (() -> Void)!) {
        if jitsiViewController == jitsiVC {
            dismissGroupCallVC(jitsiViewController)
            self.presentCallBar(for: jitsiViewController, completion: completion)
        }
    }
    
}

#endif
