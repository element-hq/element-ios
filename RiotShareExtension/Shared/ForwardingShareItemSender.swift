// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objcMembers
class ForwardingShareItemSender: NSObject, ShareItemSenderProtocol {
    
    static let errorDomain = "ForwardingShareItemSenderErrorDomain"

    enum ErrorCode: Int {
        case eventNotSentYet
    }
    
    private let event: MXEvent
    
    weak var delegate: ShareItemSenderDelegate?
    
    @objc public init(withEvent event: MXEvent) {
        self.event = event
    }
    
    func sendItems(to rooms: [MXRoom], success: @escaping () -> Void, failure: @escaping ([Error]) -> Void) {
        guard event.sentState == MXEventSentStateSent else {
            MXLog.error("[ForwardingShareItemSender] Cannot forward unsent event")
            failure([NSError(domain: Self.errorDomain,
                            code: ErrorCode.eventNotSentYet.rawValue,
                            userInfo: nil)])
            return
        }
        
        self.delegate?.shareItemSenderDidStartSending(self)
        
        var errors = [Error]()
        
        let dispatchGroup = DispatchGroup()
        for room in rooms {
            dispatchGroup.enter()
            
            var localEcho: MXEvent?
            room.sendMessage(withContent: event.content, threadId: nil, localEcho: &localEcho) { result in
                switch result {
                case .failure(let innerError):
                    errors.append(innerError)
                default:
                    room.summary.resetLastMessage(nil, failure: nil, commit: false)
                    break
                }
                
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) {
            guard errors.count == 0 else {
                failure(errors)
                return
            }
            
            success()
        }
    }
}
