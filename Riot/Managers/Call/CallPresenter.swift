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
    
    /// Utilized sessions
    private var sessions: [MXSession] = []
    /// Call view controllers map. Keys are callIds.
    private var callVCs: [String: CallViewController] = [:]
    /// Call background tasks map. Keys are callIds.
    private var callBackgroundTasks: [String: MXBackgroundTask] = [:]
    /// Actively presented direct call view controller.
    private weak var presentedCallVC: UIViewController? {
        didSet {
            updateOnHoldCall()
        }
    }
    private weak var pipCallVC: UIViewController?
    /// UI operation queue for various UI operations
    private var uiOperationQueue: OperationQueue = .main
    /// Flag to indicate whether the presenter is active.
    private var isStarted: Bool = false
    #if canImport(JitsiMeetSDK)
    private var widgetEventsListener: Any?
    /// Jitsi calls map. Keys are CallKit call UUIDs, values are corresponding widgets.
    private var jitsiCalls: [UUID: Widget] = [:]
    /// The current Jitsi view controller being displayed or not.
    private(set) var jitsiVC: JitsiViewController? {
        didSet {
            updateOnHoldCall()
        }
    }
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
        MXLog.debug("[CallPresenter] start")
        
        addCallObservers()
    }
    
    /// Stop the service
    func stop() {
        MXLog.debug("[CallPresenter] stop")
        
        removeCallObservers()
    }
    
    //  MARK - Group Calls
    
    /// Open the Jitsi view controller from a widget.
    /// - Parameter widget: the jitsi widget
    func displayJitsiCall(withWidget widget: Widget) {
        MXLog.debug("[CallPresenter] displayJitsiCall: for widget: \(widget.widgetId)")
        
        #if canImport(JitsiMeetSDK)
        let createJitsiBlock = { [weak self] in
            guard let self = self else { return }
            self.jitsiVC = JitsiViewController()
            self.jitsiVC?.openWidget(widget, withVideo: true, success: { [weak self] in
                guard let self = self else { return }
                if let jitsiVC = self.jitsiVC {
                    jitsiVC.delegate = self
                    self.presentCallVC(jitsiVC)
                    self.startJitsiCall(withWidget: widget)
                }
            }, failure: { [weak self] (error) in
                guard let self = self else { return }
                self.jitsiVC = nil
                AppDelegate.theDelegate().showAlert(withTitle: nil,
                                                    message: VectorL10n.callJitsiError)
            })
        }
        
        if let jitsiVC = jitsiVC {
            if jitsiVC.widget.widgetId == widget.widgetId {
                self.presentCallVC(jitsiVC)
            } else {
                //  end previous Jitsi call first
                endActiveJitsiCall()
                createJitsiBlock()
            }
        } else {
            createJitsiBlock()
        }
        
        #else
        AppDelegate.theDelegate().showAlert(withTitle: nil,
                                            message: VectorL10n.notSupportedYet)
        #endif
    }
    
    private func startJitsiCall(withWidget widget: Widget) {
        MXLog.debug("[CallPresenter] startJitsiCall")
        
        if let uuid = self.jitsiCalls.first(where: { $0.value.widgetId == widget.widgetId })?.key {
            //  this Jitsi call is already managed by this class, no need to report the call again
            MXLog.debug("[CallPresenter] startJitsiCall: already managed with id: \(uuid.uuidString)")
            return
        }
        
        guard let roomId = widget.roomId else {
            MXLog.debug("[CallPresenter] startJitsiCall: no roomId on widget")
            return
        }
        
        guard let session = sessions.first else {
            MXLog.debug("[CallPresenter] startJitsiCall: no active session")
            return
        }
        
        guard let room = session.room(withRoomId: roomId) else {
            MXLog.debug("[CallPresenter] startJitsiCall: unknown room: \(roomId)")
            return
        }
        
        let newUUID = UUID()
        let handle = CXHandle(type: .generic, value: roomId)
        let startCallAction = CXStartCallAction(call: newUUID, handle: handle)
        let transaction = CXTransaction(action: startCallAction)
        
        MXLog.debug("[CallPresenter] startJitsiCall: new call with id: \(newUUID.uuidString)")
        
        JMCallKitProxy.request(transaction) { (error) in
            MXLog.debug("[CallPresenter] startJitsiCall: JMCallKitProxy returned \(String(describing: error))")
            
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
        MXLog.debug("[CallPresenter] endActiveJitsiCall")
        
        guard let jitsiVC = jitsiVC else {
            //  there is no active Jitsi call
            MXLog.debug("[CallPresenter] endActiveJitsiCall: no active Jitsi call")
            return
        }
        
        if pipCallVC == jitsiVC {
            //  this call currently in the PiP mode,
            //  first present it by exiting PiP mode and then dismiss it
            exitPipCallVC(jitsiVC)
        }
        
        dismissCallVC(jitsiVC)
        jitsiVC.hangup()
        
        self.jitsiVC = nil
        
        guard let widget = jitsiVC.widget else {
            MXLog.debug("[CallPresenter] endActiveJitsiCall: no Jitsi widget for the active call")
            return
        }
        guard let uuid = self.jitsiCalls.first(where: { $0.value.widgetId == widget.widgetId })?.key else {
            //  this Jitsi call is not managed by this class
            MXLog.debug("[CallPresenter] endActiveJitsiCall: Not managed Jitsi call: \(widget.widgetId)")
            return
        }
        
        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)
        
        MXLog.debug("[CallPresenter] endActiveJitsiCall: ended call with id: \(uuid.uuidString)")
        
        JMCallKitProxy.request(transaction) { (error) in
            MXLog.debug("[CallPresenter] endActiveJitsiCall: JMCallKitProxy returned \(String(describing: error))")
            if error == nil {
                self.jitsiCalls.removeValue(forKey: uuid)
            }
        }
    }
    
    func processWidgetEvent(_ event: MXEvent, inSession session: MXSession) {
        MXLog.debug("[CallPresenter] processWidgetEvent")
        
        guard let widget = Widget(widgetEvent: event, inMatrixSession: session) else {
            MXLog.debug("[CallPresenter] processWidgetEvent: widget couldn't be created")
            return
        }
        
        guard JMCallKitProxy.isProviderConfigured() else {
            //  CallKit proxy is not configured, no benefit in parsing the event
            MXLog.debug("[CallPresenter] processWidgetEvent: JMCallKitProxy not configured")
            hangupUnhandledCallIfNeeded(widget)
            return
        }
        
        if widget.isActive {
            if let uuid = self.jitsiCalls.first(where: { $0.value.widgetId == widget.widgetId })?.key {
                //  this Jitsi call is already managed by this class, no need to report the call again
                MXLog.debug("[CallPresenter] processWidgetEvent: Jitsi call already managed with id: \(uuid.uuidString)")
                return
            }
            
            guard widget.type == kWidgetTypeJitsiV1 || widget.type == kWidgetTypeJitsiV2 else {
                //  not a Jitsi widget, ignore
                MXLog.debug("[CallPresenter] processWidgetEvent: not a Jitsi widget")
                return
            }
            
            if let jitsiVC = jitsiVC,
               jitsiVC.widget.widgetId == widget.widgetId {
                //  this is already the Jitsi call we have atm
                MXLog.debug("[CallPresenter] processWidgetEvent: ongoing Jitsi call")
                return
            }
            
            if TimeInterval(event.age)/MSEC_PER_SEC > Constants.groupCallInviteLifetime {
                //  too late to process the event
                MXLog.debug("[CallPresenter] processWidgetEvent: expired call invite")
                return
            }
            
            //  an active Jitsi widget
            let newUUID = UUID()
            
            //  assume this Jitsi call will survive
            self.jitsiCalls[newUUID] = widget
            
            if event.sender == session.myUserId {
                //  outgoing call
                MXLog.debug("[CallPresenter] processWidgetEvent: Report outgoing call with id: \(newUUID.uuidString)")
                JMCallKitProxy.reportOutgoingCall(with: newUUID, connectedAt: nil)
            } else {
                //  incoming call
                guard RiotSettings.shared.enableRingingForGroupCalls else {
                    //  do not ring for Jitsi calls
                    return
                }
                let user = session.user(withUserId: event.sender)
                let displayName = NSString.localizedUserNotificationString(forKey: "GROUP_CALL_FROM_USER",
                                                                           arguments: [user?.displayname as Any])
                
                MXLog.debug("[CallPresenter] processWidgetEvent: Report new incoming call with id: \(newUUID.uuidString)")
                
                JMCallKitProxy.reportNewIncomingCall(UUID: newUUID,
                                                     handle: widget.roomId,
                                                     displayName: displayName,
                                                     hasVideo: true) { (error) in
                    MXLog.debug("[CallPresenter] processWidgetEvent: JMCallKitProxy returned \(String(describing: error))")
                    
                    if error != nil {
                        self.jitsiCalls.removeValue(forKey: newUUID)
                    }
                }
            }
        } else {
            guard let uuid = self.jitsiCalls.first(where: { $0.value.widgetId == widget.widgetId })?.key else {
                //  this Jitsi call is not managed by this class
                MXLog.debug("[CallPresenter] processWidgetEvent: not managed Jitsi call: \(widget.widgetId)")
                hangupUnhandledCallIfNeeded(widget)
                return
            }
            MXLog.debug("[CallPresenter] processWidgetEvent: ended call with id: \(uuid.uuidString)")
            JMCallKitProxy.reportCall(with: uuid, endedAt: nil, reason: .remoteEnded)
            self.jitsiCalls.removeValue(forKey: uuid)
        }
    }
    
    //  MARK: - Private
    
    private func updateOnHoldCall() {
        guard let presentedCallVC = presentedCallVC as? CallViewController else {
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
               !self.uiOperationQueue.containsEnterPiPOperation,
               let oldCall = oldCallVC.mxCall,
               oldCall.state != .ended {
                //  present the call screen after dismissing this one
                self.presentCallVC(oldCallVC)
            }
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
    
    private func logCallVC(_ callVC: UIViewController, log: String) {
        if let callVC = callVC as? CallViewController {
            MXLog.debug("[CallPresenter] \(log): Matrix call: \(String(describing: callVC.mxCall?.callId))")
        } else if let callVC = callVC as? JitsiViewController {
            MXLog.debug("[CallPresenter] \(log): Jitsi call: \(callVC.widget.widgetId)")
        }
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
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(callTileTapped(_:)),
                                               name: .RoomCallTileTapped,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(groupCallTileTapped(_:)),
                                               name: .RoomGroupCallTileTapped,
                                               object: nil)
        
        isStarted = true
        
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
        
        isStarted = false
        
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
        
        if !call.isIncoming {
            //  put other native calls on hold
            callVCs.values.forEach({ $0.mxCall.hold(true) })
            
            //  terminate Jitsi calls
            endActiveJitsiCall()
        }
        
        callVCs[call.callId] = newCallVC
        
        if UIApplication.shared.applicationState == .background && call.isIncoming {
            // Create backgound task.
            // Without CallKit this will allow us to play vibro until the call was ended
            // With CallKit we'll inform the system when the call is ended to let the system terminate our app to save resources
            let handler = MXSDKOptions.sharedInstance().backgroundModeHandler
            let callBackgroundTask = handler.startBackgroundTask(withName: "[CallPresenter] addMatrixCallObserver", expirationHandler: nil)
            
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
            MXLog.debug("[CallPresenter] callStateChanged: call created answer: \(call.callId)")
            if call.isIncoming, isCallKitEnabled, let callVC = callVCs[call.callId] {
                presentCallVC(callVC)
            }
        case .connected:
            MXLog.debug("[CallPresenter] callStateChanged: call connected: \(call.callId)")
        case .onHold:
            MXLog.debug("[CallPresenter] callStateChanged: call holded: \(call.callId)")
            callHolded(withCallId: call.callId)
        case .remotelyOnHold:
            MXLog.debug("[CallPresenter] callStateChanged: call remotely holded: \(call.callId)")
            callHolded(withCallId: call.callId)
        case .ended:
            MXLog.debug("[CallPresenter] callStateChanged: call ended: \(call.callId)")
            endCall(withCallId: call.callId)
        default:
            break
        }
    }
    
    @objc
    private func callTileTapped(_ notification: Notification) {
        MXLog.debug("[CallPresenter] callTileTapped")
        
        guard let bubbleData = notification.object as? RoomBubbleCellData else {
            return
        }
        
        guard let randomEvent = bubbleData.allLinkedEvents().randomElement() else {
            return
        }
        
        guard let callEventContent = MXCallEventContent(fromJSON: randomEvent.content) else {
            return
        }
        
        MXLog.debug("[CallPresenter] callTileTapped: for call: \(callEventContent.callId)")
        
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
        
        if callVC == pipCallVC {
            exitPipCallVC(callVC)
        } else {
            presentCallVC(callVC)
        }
    }
    
    @objc
    private func groupCallTileTapped(_ notification: Notification) {
        MXLog.debug("[CallPresenter] groupCallTileTapped")
        
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
        
        MXLog.debug("[CallPresenter] groupCallTileTapped: for call: \(widget.widgetId)")
        
        guard let jitsiVC = jitsiVC,
              jitsiVC.widget.widgetId == widget.widgetId else {
            return
        }
        
        if jitsiVC == pipCallVC {
            exitPipCallVC(jitsiVC)
        } else {
            presentCallVC(jitsiVC)
        }
    }
    
    //  MARK: - Call Screens
    
    private func presentCallVC(_ callVC: UIViewController, completion: (() -> Void)? = nil) {
        logCallVC(callVC, log: "presentCallVC")
        
        //  do not use PiP transitions here, as we really want to present the screen
        callVC.transitioningDelegate = nil
        
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
    
    private func dismissCallVC(_ callVC: UIViewController, completion: (() -> Void)? = nil) {
        logCallVC(callVC, log: "dismissCallVC")
        
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
    
    private func enterPipCallVC(_ callVC: UIViewController, completion: (() -> Void)? = nil) {
        logCallVC(callVC, log: "enterPipCallVC")
        
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
    
    private func exitPipCallVC(_ callVC: UIViewController, completion: (() -> Void)? = nil) {
        logCallVC(callVC, log: "exitPipCallVC")
        
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
    
    /// Hangs up current Jitsi call, if it is inactive and associated with given widget.
    /// Should be used for calls that are not handled through JMCallKitProxy,
    /// as these should be removed regardless.
    private func hangupUnhandledCallIfNeeded(_ widget: Widget) {
        guard !widget.isActive, widget.widgetId == jitsiVC?.widget.widgetId else { return }
        
        MXLog.debug("[CallPresenter] hangupUnhandledCallIfNeeded: ending call with Widget id: %@", widget.widgetId)
        endActiveJitsiCall()
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
            //  go to pip mode here
            enterPipCallVC(callVC, completion: completion)
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
    
    var containsEnterPiPOperation: Bool {
        return containsOperation(ofType: CallVCEnterPipOperation.self)
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
            dismissCallVC(jitsiVC)
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

//  MARK: - JitsiViewControllerDelegate

extension CallPresenter: JitsiViewControllerDelegate {
    
    func jitsiViewController(_ jitsiViewController: JitsiViewController!, dismissViewJitsiController completion: (() -> Void)!) {
        if jitsiViewController == jitsiVC {
            endActiveJitsiCall()
        }
    }
    
    func jitsiViewController(_ jitsiViewController: JitsiViewController!, goBackToApp completion: (() -> Void)!) {
        if jitsiViewController == jitsiVC {
            enterPipCallVC(jitsiViewController, completion: completion)
        }
    }
    
}

#endif
