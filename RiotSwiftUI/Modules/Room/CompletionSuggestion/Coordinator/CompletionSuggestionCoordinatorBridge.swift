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

@objc
protocol CompletionSuggestionCoordinatorBridgeDelegate: AnyObject {
    func completionSuggestionCoordinatorBridge(_ coordinator: CompletionSuggestionCoordinatorBridge, didRequestMentionForMember member: MXRoomMember, textTrigger: String?)
    func completionSuggestionCoordinatorBridgeDidRequestMentionForRoom(_ coordinator: CompletionSuggestionCoordinatorBridge, textTrigger: String?)
    func completionSuggestionCoordinatorBridge(_ coordinator: CompletionSuggestionCoordinatorBridge, didRequestCommand command: String, textTrigger: String?)
    func completionSuggestionCoordinatorBridge(_ coordinator: CompletionSuggestionCoordinatorBridge, didUpdateViewHeight height: CGFloat)
}

@objcMembers
final class CompletionSuggestionCoordinatorBridge: NSObject {
    private var _completionSuggestionCoordinator: Any?
    fileprivate var completionSuggestionCoordinator: CompletionSuggestionCoordinator {
        _completionSuggestionCoordinator as! CompletionSuggestionCoordinator
    }
    
    weak var delegate: CompletionSuggestionCoordinatorBridgeDelegate?
    
    init(mediaManager: MXMediaManager, room: MXRoom, userID: String) {
        let parameters = CompletionSuggestionCoordinatorParameters(mediaManager: mediaManager, room: room, userID: userID)
        let completionSuggestionCoordinator = CompletionSuggestionCoordinator(parameters: parameters)
        _completionSuggestionCoordinator = completionSuggestionCoordinator
        
        super.init()
        
        completionSuggestionCoordinator.delegate = self
    }
    
    func processTextMessage(_ textMessage: String) {
        completionSuggestionCoordinator.processTextMessage(textMessage)
    }

    func processSuggestionPattern(_ suggestionPatternWrapper: SuggestionPatternWrapper) {
        completionSuggestionCoordinator.processSuggestionPattern(suggestionPatternWrapper.suggestionPattern)
    }
    
    func toPresentable() -> UIViewController? {
        completionSuggestionCoordinator.toPresentable()
    }

    func sharedContext() -> CompletionSuggestionViewModelContextWrapper {
        completionSuggestionCoordinator.sharedContext()
    }
}

extension CompletionSuggestionCoordinatorBridge: CompletionSuggestionCoordinatorDelegate {
    func completionSuggestionCoordinator(_ coordinator: CompletionSuggestionCoordinator, didRequestMentionForMember member: MXRoomMember, textTrigger: String?) {
        delegate?.completionSuggestionCoordinatorBridge(self, didRequestMentionForMember: member, textTrigger: textTrigger)
    }
    
    func completionSuggestionCoordinatorDidRequestMentionForRoom(_ coordinator: CompletionSuggestionCoordinator, textTrigger: String?) {
        delegate?.completionSuggestionCoordinatorBridgeDidRequestMentionForRoom(self, textTrigger: textTrigger)
    }

    func completionSuggestionCoordinator(_ coordinator: CompletionSuggestionCoordinator, didRequestCommand command: String, textTrigger: String?) {
        delegate?.completionSuggestionCoordinatorBridge(self, didRequestCommand: command, textTrigger: textTrigger)
    }

    func completionSuggestionCoordinator(_ coordinator: CompletionSuggestionCoordinator, didUpdateViewHeight height: CGFloat) {
        delegate?.completionSuggestionCoordinatorBridge(self, didUpdateViewHeight: height)
    }
}
