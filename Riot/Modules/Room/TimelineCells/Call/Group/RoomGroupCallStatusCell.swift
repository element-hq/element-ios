// 
// Copyright 2021 New Vector Ltd
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

import UIKit

/// The number of milliseconds in one second.
private let MSEC_PER_SEC: TimeInterval = 1000

@objcMembers
class RoomGroupCallStatusCell: RoomCallBaseCell {
    
    private static var className: String {
        return String(describing: self)
    }
    
    /// Action identifier used when the user pressed "Join" button for an active call.
    /// The `userInfo` dictionary contains an `MXEvent` object under the `kMXKRoomBubbleCellEventKey` key, representing the widget event of the call.
    static var joinAction: String {
        return self.className + ".join"
    }
    
    /// Action identifier used when the user pressed "Leave" button for an active call.
    /// The `userInfo` dictionary contains an `MXEvent` object under the `kMXKRoomBubbleCellEventKey` key, representing the widget event of the call.
    static var leaveAction: String {
        return self.className + ".leave"
    }
    
    /// Action identifier used when the user pressed "Answer" button for an incoming call.
    /// The `userInfo` dictionary contains an `MXEvent` object under the `kMXKRoomBubbleCellEventKey` key, representing the widget event of the call.
    static var answerAction: String {
        return self.className + ".answer"
    }
    
    /// Action identifier used when the user pressed "Decline" button for an incoming call.
    /// The `userInfo` dictionary contains an `MXEvent` object under the `kMXKRoomBubbleCellEventKey` key, representing the widget event of the call.
    static var declineAction: String {
        return self.className + ".decline"
    }

    private var callDurationString: String = ""
    private var isIncoming: Bool = false
    private var widgetEvent: MXEvent!
    private var widgetId: String!
    private var viewState: ViewState = .unknown {
        didSet {
            updateBottomContentView()
        }
    }
    
    private enum Constants {
        static let secondsToDisplayAnswerDeclineOptions: TimeInterval = 30
    }
    
    private enum ViewState {
        case unknown
        case ringing
        case active
        case declined
        case ended
    }
    
    private static var callDurationFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .dropAll
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter
    }
    
    private func updateBottomContentView() {
        bottomContentView = bottomView(for: viewState)
    }
    
    private var callTypeIcon: UIImage {
        //  always return a video call icon
        return Asset.Images.callVideoIcon.image
    }
    
    private var isJoined: Bool {
        return widgetId != nil &&
            AppDelegate.theDelegate().callPresenter.jitsiVC?.widget.widgetId == widgetId
    }
    
    private var actionUserInfo: [AnyHashable: Any]? {
        if let event = widgetEvent {
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
            view.secondButton.setImage(callTypeIcon, for: .normal)
            view.secondButton.removeTarget(nil, action: nil, for: .touchUpInside)
            view.secondButton.addTarget(self, action: #selector(answerCallAction(_:)), for: .touchUpInside)
            
            return view
        case .active:
            let view = HorizontalButtonsContainerView.loadFromNib()
            view.secondButton.isHidden = true
            
            if isJoined {
                //  show a "Leave" button
                view.firstButton.style = .negative
                view.firstButton.setTitle(VectorL10n.eventFormatterGroupCallLeave, for: .normal)
                view.firstButton.setImage(nil, for: .normal)
                view.firstButton.removeTarget(nil, action: nil, for: .touchUpInside)
                view.firstButton.addTarget(self, action: #selector(leaveAction(_:)), for: .touchUpInside)
            } else {
                //  show a "Join" button
                view.firstButton.style = .positive
                view.firstButton.setTitle(VectorL10n.eventFormatterGroupCallJoin, for: .normal)
                view.firstButton.setImage(callTypeIcon, for: .normal)
                view.firstButton.removeTarget(nil, action: nil, for: .touchUpInside)
                view.firstButton.addTarget(self, action: #selector(joinAction(_:)), for: .touchUpInside)
            }
            
            return view
        case .declined:
            let view = HorizontalButtonsContainerView.loadFromNib()
            view.secondButton.isHidden = true
            
            view.firstButton.style = .positive
            view.firstButton.setTitle(VectorL10n.eventFormatterGroupCallJoin, for: .normal)
            view.firstButton.setImage(callTypeIcon, for: .normal)
            view.firstButton.removeTarget(nil, action: nil, for: .touchUpInside)
            view.firstButton.addTarget(self, action: #selector(joinAction(_:)), for: .touchUpInside)
            
            return view
        case .ended:
            return nil
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
    private func joinAction(_ sender: CallTileActionButton) {
        self.delegate?.cell(self,
                            didRecognizeAction: Self.joinAction,
                            userInfo: actionUserInfo)
    }
    
    @objc
    private func leaveAction(_ sender: CallTileActionButton) {
        self.delegate?.cell(self,
                            didRecognizeAction: Self.leaveAction,
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
    
    //  MARK: - MXKCellRendering
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        viewState = .unknown
        
        guard let bubbleCellData = cellData as? RoomBubbleCellData else {
            return
        }
        
        let events = bubbleCellData.allLinkedEvents()
        
        MXLog.debug("[RoomGroupCallStatusBubbleCell] render: \(events.count) events: \(events)")
        
        guard let widgetEvent = events
                .first(where: {
                    $0.eventType == .custom &&
                        ($0.type == kWidgetMatrixEventTypeString || $0.type == kWidgetModularEventTypeString)
                }) else {
            return
        }
        
        guard let widgetId = widgetEvent.stateKey else {
            return
        }
        
        guard let room = bubbleCellData.mxSession.room(withRoomId: widgetEvent.roomId) else {
            return
        }
        
        callDurationString = readableCallDuration(from: widgetEvent, endEvent: nil)
        isIncoming = widgetEvent.sender != bubbleCellData.mxSession.myUserId
        self.widgetEvent = widgetEvent
        self.widgetId = widgetId
        innerContentView.callIconView.image = Asset.Images.callVideoIcon.image
        
        if isIncoming && !isJoined &&
            TimeInterval(widgetEvent.age)/MSEC_PER_SEC < Constants.secondsToDisplayAnswerDeclineOptions {
            
            if JitsiService.shared.isWidgetDeclined(withId: widgetId) {
                innerContentView.callerNameLabel.text = room.summary.displayname
                room.summary.setRoomAvatarImageIn(innerContentView.avatarImageView)
                
                viewState = .declined
                statusText = VectorL10n.eventFormatterCallYouDeclined
            } else {
                innerContentView.callerNameLabel.text = VectorL10n.eventFormatterGroupCallIncoming(bubbleCellData.senderDisplayName, room.summary.displayname)
                
                innerContentView.avatarImageView.setImageURI(bubbleCellData.senderAvatarUrl,
                                            withType: nil,
                                            andImageOrientation: .up,
                                            toFitViewSize: innerContentView.avatarImageView.frame.size,
                                            with: MXThumbnailingMethodCrop,
                                            previewImage: bubbleCellData.senderAvatarPlaceholder,
                                            mediaManager: bubbleCellData.mxSession.mediaManager)
                
                viewState = .ringing
                statusText = nil
            }
        } else {
            innerContentView.callerNameLabel.text = room.summary.displayname
            
            room.summary.setRoomAvatarImageIn(innerContentView.avatarImageView)
        }
        
        innerContentView.avatarImageView.defaultBackgroundColor = .clear
        
        room.state { [weak self] (roomState) in
            guard let self = self else { return }
            guard let widgets = WidgetManager.shared()?.widgets(ofTypes: [
                kWidgetTypeJitsiV1,
                kWidgetTypeJitsiV2
            ],
            in: room,
            with: roomState) else {
                self.viewState = .ended
                self.updateStatusTextForEndedCall()
                return
            }
            
            let removeWidgetEvent = roomState?.stateEvents
                .filter({ $0.stateKey == widgetId })
                .first(where: { $0.content.isEmpty })
            self.callDurationString = self.readableCallDuration(from: widgetEvent,
                                                                endEvent: removeWidgetEvent)

            guard let widget = widgets.first(where: { $0.widgetId == widgetId }) else {
                self.viewState = .ended
                self.updateStatusTextForEndedCall()
                return
            }

            if widget.isActive {
                if !self.isIncoming {
                    self.viewState = .active
                    self.statusText = VectorL10n.eventFormatterCallActiveVideo
                } else if !self.isJoined &&
                            TimeInterval(widgetEvent.age)/MSEC_PER_SEC < Constants.secondsToDisplayAnswerDeclineOptions {
                    
                    if JitsiService.shared.isWidgetDeclined(withId: widgetId) {
                        self.viewState = .declined
                        self.statusText = VectorL10n.eventFormatterCallYouDeclined
                    } else {
                        self.viewState = .ringing
                        self.statusText = nil
                    }
                } else {
                    self.viewState = .active
                    self.statusText = VectorL10n.eventFormatterCallActiveVideo
                }
            } else {
                self.viewState = .ended
                self.updateStatusTextForEndedCall()
            }
        }
    }
    
    private func callDuration(from startEvent: MXEvent?, endEvent: MXEvent?) -> TimeInterval {
        guard let startDate = startEvent?.originServerTs else {
            //  never started
            return 0
        }
        guard let endDate = endEvent?.originServerTs else {
            //  not ended yet, compute the diff from now
            return (NSTimeIntervalSince1970 - TimeInterval(startDate))/MSEC_PER_SEC
        }
        
        //  ended, compute the diff between two dates
        return TimeInterval(max(0, Double(endDate) - Double(startDate)))/MSEC_PER_SEC
    }
    
    private func readableCallDuration(from startEvent: MXEvent?, endEvent: MXEvent?) -> String {
        let duration = callDuration(from: startEvent, endEvent: endEvent)
        
        if duration <= 0 {
            return ""
        }
        
        return RoomGroupCallStatusCell.callDurationFormatter.string(from: duration) ?? ""
    }

}
