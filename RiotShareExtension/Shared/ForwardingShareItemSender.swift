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
