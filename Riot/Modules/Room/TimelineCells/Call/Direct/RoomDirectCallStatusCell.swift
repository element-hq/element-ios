// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

/// The number of milliseconds in one second.
private let MSEC_PER_SEC: TimeInterval = 1000

@objcMembers
class RoomDirectCallStatusCell: RoomCallBaseCell {
    
    private static var className: String {
        return String(describing: self)
    }
    
    /// Action identifier used when the user pressed "Call back" button for a declined call.
    /// The `userInfo` dictionary contains an `MXEvent` object under the `kMXKRoomBubbleCellEventKey` key, representing the invite event of the declined call.
    static var callBackAction: String {
        return self.className + ".callBack"
    }
    
    /// Action identifier used when the user pressed "Answer" button for an incoming call.
    /// The `userInfo` dictionary contains an `MXEvent` object under the `kMXKRoomBubbleCellEventKey` key, representing the invite event of the call.
    static var answerAction: String {
        return self.className + ".answer"
    }
    
    /// Action identifier used when the user pressed "Decline" button for an incoming call.
    /// The `userInfo` dictionary contains an `MXEvent` object under the `kMXKRoomBubbleCellEventKey` key, representing the invite event of the call.
    static var declineAction: String {
        return self.className + ".decline"
    }
    
    /// Action identifier used when the user pressed "End call" button for an incoming call.
    /// The `userInfo` dictionary contains an `MXEvent` object under the `kMXKRoomBubbleCellEventKey` key, representing the invite event of the call.
    static var endCallAction: String {
        return self.className + ".endCall"
    }
    
    private var callDurationString: String = ""
    private var isVideoCall: Bool = false
    private var isIncoming: Bool = false
    private var callInviteEvent: MXEvent?
    private var viewState: ViewState = .unknown {
        didSet {
            updateBottomContentView()
            updateCallIcon()
        }
    }
    
    private enum ViewState {
        case unknown
        case ringing
        case active
        case declined
        case missed
        case ended
        case failed
    }
    
    private static var callDurationFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .dropAll
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter
    }
    
    private func updateCallIcon() {
        switch viewState {
        case .missed:
            innerContentView.callIconView.image = isVideoCall ?
                Asset.Images.callMissedVideo.image :
                Asset.Images.callMissedVoice.image
        default:
            innerContentView.callIconView.image = isVideoCall ?
                Asset.Images.callVideoIcon.image :
                Asset.Images.voiceCallHangonIcon.image
        }
    }
    
    private func updateBottomContentView() {
        bottomContentView = bottomView(for: viewState)
    }
    
    private var callButtonIcon: UIImage {
        if isVideoCall {
            return Asset.Images.callVideoIcon.image
        } else {
            return Asset.Images.voiceCallHangonIcon.image
        }
    }
    
    private var actionUserInfo: [AnyHashable: Any]? {
        if let event = callInviteEvent {
            return [kMXKRoomBubbleCellEventKey: event]
        }
        return nil
    }
    
    private func bottomView(for state: ViewState) -> UIView? {
        switch state {
        case .unknown:
            return nil
        case .ringing:
            let view = HorizontalButtonsContainerView.loadFromNib()
            
            view.firstButton.style = .negative
            view.firstButton.setTitle(VectorL10n.eventFormatterCallDecline, for: .normal)
            view.firstButton.setImage(Asset.Images.voiceCallHangupIcon.image, for: .normal)
            view.firstButton.removeTarget(nil, action: nil, for: .touchUpInside)
            view.firstButton.addTarget(self, action: #selector(declineCallAction(_:)), for: .touchUpInside)
            
            view.secondButton.style = .positive
            view.secondButton.setTitle(VectorL10n.eventFormatterCallAnswer, for: .normal)
            view.secondButton.setImage(callButtonIcon, for: .normal)
            view.secondButton.removeTarget(nil, action: nil, for: .touchUpInside)
            view.secondButton.addTarget(self, action: #selector(answerCallAction(_:)), for: .touchUpInside)
            
            return view
        case .active:
            let view = HorizontalButtonsContainerView.loadFromNib()
            view.secondButton.isHidden = true
            
            view.firstButton.style = .negative
            view.firstButton.setTitle(VectorL10n.eventFormatterCallEndCall, for: .normal)
            view.firstButton.setImage(Asset.Images.voiceCallHangupIcon.image, for: .normal)
            view.firstButton.removeTarget(nil, action: nil, for: .touchUpInside)
            view.firstButton.addTarget(self, action: #selector(endCallAction(_:)), for: .touchUpInside)
            
            return view
        case .declined:
            let view = HorizontalButtonsContainerView.loadFromNib()
            view.secondButton.isHidden = true
            
            view.firstButton.style = .positive
            view.firstButton.setTitle(VectorL10n.eventFormatterCallBack, for: .normal)
            view.firstButton.setImage(callButtonIcon, for: .normal)
            view.firstButton.removeTarget(nil, action: nil, for: .touchUpInside)
            view.firstButton.addTarget(self, action: #selector(callBackAction(_:)), for: .touchUpInside)
            
            return view
        case .missed:
            let view = HorizontalButtonsContainerView.loadFromNib()
            view.secondButton.isHidden = true
            
            view.firstButton.style = .positive
            view.firstButton.setTitle(VectorL10n.eventFormatterCallBack, for: .normal)
            view.firstButton.setImage(callButtonIcon, for: .normal)
            view.firstButton.removeTarget(nil, action: nil, for: .touchUpInside)
            view.firstButton.addTarget(self, action: #selector(callBackAction(_:)), for: .touchUpInside)
            
            return view
        case .ended:
            return nil
        case .failed:
            let view = HorizontalButtonsContainerView.loadFromNib()
            view.secondButton.isHidden = true
            
            view.firstButton.style = .positive
            view.firstButton.setTitle(VectorL10n.eventFormatterCallRetry, for: .normal)
            view.firstButton.setImage(callButtonIcon, for: .normal)
            view.firstButton.removeTarget(nil, action: nil, for: .touchUpInside)
            view.firstButton.addTarget(self, action: #selector(callBackAction(_:)), for: .touchUpInside)
            
            return view
        }
    }
    
    private func configure(withCall call: MXCall) {
        switch call.state {
        case .fledgling,
            .waitLocalMedia,
            .createOffer,
            .connecting:
            viewState = .active
            if call.isIncoming {
                statusText = isVideoCall ? VectorL10n.eventFormatterCallActiveVideo : VectorL10n.eventFormatterCallActiveVoice
            } else {
                statusText = VectorL10n.eventFormatterCallConnecting
            }
        case .inviteSent:
            if call.isIncoming {
                statusText = isVideoCall ? VectorL10n.eventFormatterCallActiveVideo : VectorL10n.eventFormatterCallActiveVoice
            } else {
                statusText = VectorL10n.eventFormatterCallRinging
            }
        case .createAnswer,
             .connected,
             .onHold,
             .remotelyOnHold:
            viewState = .active
            statusText = isVideoCall ? VectorL10n.eventFormatterCallActiveVideo : VectorL10n.eventFormatterCallActiveVoice
        case .ringing:
            if call.isIncoming {
                viewState = .ringing
                statusText = isVideoCall ? VectorL10n.eventFormatterCallIncomingVideo : VectorL10n.eventFormatterCallIncomingVoice
            } else {
                viewState = .active
                statusText = isVideoCall ? VectorL10n.eventFormatterCallActiveVideo : VectorL10n.eventFormatterCallActiveVoice
            }
        case .ended:
            switch call.endReason {
            case .unknown,
                 .hangup,
                 .hangupElsewhere,
                 .remoteHangup,
                 .answeredElseWhere:
                viewState = .ended
                updateStatusTextForEndedCall()
            case .missed:
                if call.isIncoming {
                    viewState = .missed
                    statusText = isVideoCall ? VectorL10n.eventFormatterCallMissedVideo : VectorL10n.eventFormatterCallMissedVoice
                } else {
                    updateStatusTextForEndedCall()
                }
            case .busy:
                configureForRejectedCall(call: call)
            @unknown default:
                viewState = .ended
                updateStatusTextForEndedCall()
            }
        case .inviteExpired,
             .answeredElseWhere:
            viewState = .ended
            updateStatusTextForEndedCall()
        @unknown default:
            viewState = .ended
            updateStatusTextForEndedCall()
        }
    }
    
    private func configureForRejectedCall(withEvent event: MXEvent? = nil, call: MXCall? = nil, bubbleCellData: RoomBubbleCellData? = nil) {
        
        let isMyReject: Bool
        
        if let call = call, call.isIncoming {
            isMyReject = true
        } else if let event = event, let bubbleCellData = bubbleCellData, event.sender == bubbleCellData.mxSession.myUserId {
            isMyReject = true
        } else {
            isMyReject = false
        }
        
        if isMyReject {
            viewState = .declined
            statusText = VectorL10n.eventFormatterCallYouDeclined
        } else {
            viewState = .ended
            updateStatusTextForEndedCall()
        }
    }
    
    private func configureForHangupCall(withEvent event: MXEvent) {
        guard let hangupEventContent = MXCallHangupEventContent(fromJSON: event.content) else {
            viewState = .ended
            updateStatusTextForEndedCall()
            return
        }
        
        switch hangupEventContent.reasonType {
        case .userHangup:
            viewState = .ended
            updateStatusTextForEndedCall()
        default:
            viewState = .failed
            statusText = VectorL10n.eventFormatterCallConnectionFailed
        }
    }
    
    private func configureForUnansweredCall() {
        if isIncoming {
            //  missed call
            viewState = .missed
            statusText = isVideoCall ? VectorL10n.eventFormatterCallMissedVideo : VectorL10n.eventFormatterCallMissedVoice
        } else {
            //  outgoing unanswered call
            viewState = .ended
            updateStatusTextForEndedCall()
        }
    }
    
    private func updateStatusTextForEndedCall() {
        if callDurationString.count > 0 {
            statusText = VectorL10n.eventFormatterCallHasEndedWithTime(callDurationString)
        } else {
            statusText = VectorL10n.eventFormatterCallHasEnded
        }
    }
    
    //  MARK: - Actions
    
    @objc
    private func callBackAction(_ sender: CallTileActionButton) {
        self.delegate?.cell(self,
                            didRecognizeAction: Self.callBackAction,
                            userInfo: actionUserInfo)
    }
    
    @objc
    private func declineCallAction(_ sender: CallTileActionButton) {
        self.delegate?.cell(self,
                            didRecognizeAction: Self.declineAction,
                            userInfo: actionUserInfo)
    }
    
    @objc
    private func answerCallAction(_ sender: CallTileActionButton) {
        self.delegate?.cell(self,
                            didRecognizeAction: Self.answerAction,
                            userInfo: actionUserInfo)
    }
    
    @objc
    private func endCallAction(_ sender: CallTileActionButton) {
        self.delegate?.cell(self,
                            didRecognizeAction: Self.endCallAction,
                            userInfo: actionUserInfo)
    }
    
    //  MARK: - MXKCellRendering
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        viewState = .unknown
        
        guard let bubbleCellData = cellData as? RoomBubbleCellData else {
            return
        }
        
        let events = bubbleCellData.allLinkedEvents()
        
        guard let inviteEvent = events.first(where: { $0.eventType == .callInvite }) else {
            return
        }
        
        if bubbleCellData.senderId == bubbleCellData.mxSession.myUserId {
            //  event sent by my user, no means in displaying our own avatar and display name
            if let directUserId = bubbleCellData.mxSession.directUserId(inRoom: bubbleCellData.roomId) {
                let user = bubbleCellData.mxSession.user(withUserId: directUserId)
                
                let placeholder = AvatarGenerator.generateAvatar(forMatrixItem: directUserId,
                                                                 withDisplayName: user?.displayname)
                
                innerContentView.avatarImageView.setImageURI(user?.avatarUrl,
                                            withType: nil,
                                            andImageOrientation: .up,
                                            toFitViewSize: innerContentView.avatarImageView.frame.size,
                                            with: MXThumbnailingMethodCrop,
                                            previewImage: placeholder,
                                            mediaManager: bubbleCellData.mxSession.mediaManager)
                innerContentView.avatarImageView.defaultBackgroundColor = .clear
                
                innerContentView.callerNameLabel.text = user?.displayname
            }
        } else {
            innerContentView.avatarImageView.setImageURI(bubbleCellData.senderAvatarUrl,
                                        withType: nil,
                                        andImageOrientation: .up,
                                        toFitViewSize: innerContentView.avatarImageView.frame.size,
                                        with: MXThumbnailingMethodCrop,
                                        previewImage: bubbleCellData.senderAvatarPlaceholder,
                                        mediaManager: bubbleCellData.mxSession.mediaManager)
            innerContentView.avatarImageView.defaultBackgroundColor = .clear
            
            innerContentView.callerNameLabel.text = bubbleCellData.senderDisplayName
        }
        
        guard let callInviteEventContent = MXCallInviteEventContent(fromJSON: inviteEvent.content) else {
            return
        }
        isVideoCall = callInviteEventContent.isVideoCall()
        callDurationString = readableCallDuration(from: events)
        isIncoming = inviteEvent.sender != bubbleCellData.mxSession.myUserId
        callInviteEvent = inviteEvent
        updateCallIcon()
        let callId = callInviteEventContent.callId
        guard let call = bubbleCellData.mxSession.callManager.call(withCallId: callId) else {
            
            //  check events include a reject event
            if let rejectEvent = events.first(where: { $0.eventType == .callReject }) {
                configureForRejectedCall(withEvent: rejectEvent, bubbleCellData: bubbleCellData)
                return
            }
            
            //  check events include an answer event
            if !events.contains(where: { $0.eventType == .callAnswer }) {
                configureForUnansweredCall()
                return
            }
            
            //  check events include a hangup event
            if let hangupEvent = events.first(where: { $0.eventType == .callHangup }) {
                configureForHangupCall(withEvent: hangupEvent)
                return
            }
            
            //  there is no reject or hangup event, we can just say this call has ended
            viewState = .ended
            updateStatusTextForEndedCall()
            return
        }
        
        configure(withCall: call)
    }
    
    private func callDuration(from events: [MXEvent]) -> TimeInterval {
        guard let startDate = events.first(where: { $0.eventType == .callAnswer })?.originServerTs else {
            //  never started
            return 0
        }
        guard let endDate = events.first(where: { $0.eventType == .callHangup })?.originServerTs
                ?? events.first(where: { $0.eventType == .callReject })?.originServerTs else {
            //  not ended yet, compute the diff from now
            return (NSTimeIntervalSince1970 - TimeInterval(startDate))/MSEC_PER_SEC
        }
        
        guard startDate < endDate else {
            // started but hung up/rejected on other end around the same time
            return 0
        }
        
        //  ended, compute the diff between two dates
        return TimeInterval(endDate - startDate)/MSEC_PER_SEC
    }
    
    private func readableCallDuration(from events: [MXEvent]) -> String {
        let duration = callDuration(from: events)
        
        if duration <= 0 {
            return ""
        }
        
        return RoomDirectCallStatusCell.callDurationFormatter.string(from: duration) ?? ""
    }
    
}
