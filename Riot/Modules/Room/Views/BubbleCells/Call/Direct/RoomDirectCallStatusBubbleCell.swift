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

import UIKit

class RoomDirectCallStatusBubbleCell: RoomBaseCallBubbleCell {
    
    private enum Constants {
        static let statusTextFontSize: CGFloat = 14
        static let statusTextInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 12, right: 8)
        // swiftlint:disable force_unwrapping
        static let statusCallBackURL: URL = URL(string: "element://call")!
        // swiftlint:enable force_unwrapping
    }
    
    private lazy var statusTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: Constants.statusTextFontSize)
        textView.backgroundColor = .clear
        textView.textColor = ThemeService.shared().theme.noticeSecondaryColor
        textView.linkTextAttributes = [
            .font: UIFont.systemFont(ofSize: Constants.statusTextFontSize),
            .foregroundColor: ThemeService.shared().theme.tintColor
        ]
        textView.textAlignment = .center
        textView.contentInset = .zero
        textView.isEditable = false
        textView.isSelectable = false
        textView.isScrollEnabled = false
        textView.scrollsToTop = false
        textView.textContainerInset = Constants.statusTextInsets
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        return textView
    }()
    
    override var bottomContentView: UIView? {
        return statusTextView
    }
    
    override func update(theme: Theme) {
        super.update(theme: theme)
        statusTextView.textColor = theme.noticeSecondaryColor
        statusTextView.linkTextAttributes = [
            .font: UIFont.systemFont(ofSize: Constants.statusTextFontSize),
            .foregroundColor: theme.tintColor
        ]
    }
    
    private func configure(withCall call: MXCall) {
        switch call.state {
        case .connected,
         .fledgling,
         .waitLocalMedia,
         .createOffer,
         .inviteSent,
         .createAnswer,
         .connecting,
         .onHold,
         .remotelyOnHold:
            statusTextView.text = VectorL10n.eventFormatterCallYouCurrentlyIn
        case .ringing:
            if call.isIncoming {
                //  should not be here
                statusTextView.text = nil
            } else {
                statusTextView.text = VectorL10n.eventFormatterCallYouCurrentlyIn
            }
        case .ended:
            switch call.endReason {
            case .unknown,
                 .hangup,
                 .hangupElsewhere,
                 .remoteHangup,
                 .missed,
                 .answeredElseWhere:
                statusTextView.text = VectorL10n.eventFormatterCallHasEnded
            case .busy:
                configureForRejectedCall(call: call)
            @unknown default:
                statusTextView.text = VectorL10n.eventFormatterCallHasEnded
            }
        case .inviteExpired,
             .answeredElseWhere:
            statusTextView.text = VectorL10n.eventFormatterCallHasEnded
        @unknown default:
            statusTextView.text = VectorL10n.eventFormatterCallHasEnded
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
            
            let centerParagraphStyle = NSMutableParagraphStyle()
            centerParagraphStyle.alignment = .center
            
            let mutableAttrString = NSMutableAttributedString(string: VectorL10n.eventFormatterCallYouDeclined + " " + VectorL10n.eventFormatterCallBack, attributes: [
                .font: UIFont.systemFont(ofSize: Constants.statusTextFontSize),
                .foregroundColor: ThemeService.shared().theme.noticeSecondaryColor,
                .paragraphStyle: centerParagraphStyle
            ])
            
            let range = mutableAttrString.mutableString.range(of: VectorL10n.eventFormatterCallBack)
            if range.location != NSNotFound {
                mutableAttrString.addAttribute(.link, value: Constants.statusCallBackURL, range: range)
            }
            
            statusTextView.attributedText = mutableAttrString
            statusTextView.isSelectable = true
        } else {
            statusTextView.text = VectorL10n.eventFormatterCallHasEnded
        }
    }
    
    //  MARK: - MXKCellRendering
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        guard let bubbleCellData = cellData as? RoomBubbleCellData else {
            return
        }
        
        let events = bubbleCellData.allLinkedEvents()
        
        //  getting a random event for call id is enough
        guard let randomEvent = bubbleCellData.events.randomElement() else {
            return
        }
        
        guard let callEventContent = MXCallEventContent(fromJSON: randomEvent.content) else { return }
        let callId = callEventContent.callId
        guard let call = bubbleCellData.mxSession.callManager.call(withCallId: callId) else {
            
            //  check events include a reject event
            if let rejectEvent = events.first(where: { $0.eventType == .callReject }) {
                configureForRejectedCall(withEvent: rejectEvent, bubbleCellData: bubbleCellData)
                return
            }
            
            //  there is no reject event, we can just say this call has ended
            statusTextView.text = VectorL10n.eventFormatterCallHasEnded
            return
        }
        
        configure(withCall: call)
    }
    
    override func prepareForReuse() {
        statusTextView.isSelectable = false
        statusTextView.text = nil
        statusTextView.attributedText = nil
        
        super.prepareForReuse()
    }
    
}

//  MARK: - UITextViewDelegate

extension RoomDirectCallStatusBubbleCell {
    
    override func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL == Constants.statusCallBackURL && interaction == .invokeDefaultAction {
            let userInfo: [AnyHashable: Any]?
            
            guard let bubbleCellData = bubbleData as? RoomBubbleCellData else {
                return false
            }
            let events = bubbleCellData.allLinkedEvents()
            if let callInviteEvent = events.first(where: { $0.eventType == .callInvite }) {
                userInfo = [kMXKRoomBubbleCellEventKey: callInviteEvent]
            } else {
                userInfo = nil
            }
            
            self.delegate?.cell(self, didRecognizeAction: kMXKRoomBubbleCellCallBackButtonPressed, userInfo: userInfo)
            return true
        }
        return false
    }
    
}
