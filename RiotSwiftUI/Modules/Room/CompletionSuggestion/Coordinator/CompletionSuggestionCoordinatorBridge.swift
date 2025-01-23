//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
