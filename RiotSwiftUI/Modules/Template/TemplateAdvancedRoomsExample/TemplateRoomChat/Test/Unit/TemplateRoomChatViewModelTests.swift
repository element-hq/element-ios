//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

@testable import RiotSwiftUI

class TemplateRoomChatViewModelTests: XCTestCase {
    var service: MockTemplateRoomChatService!
    var viewModel: TemplateRoomChatViewModel!
    var context: TemplateRoomChatViewModel.Context!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        service = MockTemplateRoomChatService()
        service.simulateUpdate(initializationStatus: .initialized)
        viewModel = TemplateRoomChatViewModel(templateRoomChatService: service)
        context = viewModel.context
    }
    
    func testInitialState() {
        XCTAssertEqual(context.viewState.bubbles.count, 3)
        XCTAssertEqual(context.viewState.sendButtonEnabled, false)
        XCTAssertEqual(context.viewState.roomInitializationStatus, .initialized)
    }

    func testSendMessageUpdatesReceived() throws {
        let bubblesPublisher: AnyPublisher<[[TemplateRoomChatBubble]], Never> = context.$viewState.map(\.bubbles).removeDuplicates().collect(2).first().eraseToAnyPublisher()
        let awaitDeferred = xcAwaitDeferred(bubblesPublisher)
        let newMessage = "Let's Go"
        service.send(textMessage: newMessage)
        
        let result: [[TemplateRoomChatBubble]]? = try awaitDeferred()
        
        // Test that the update to the messages in turn updates the view's
        // the last bubble by appending another text item, asserting the body.
        guard let item: TemplateRoomChatBubbleItem = result?.last?.last?.items.last,
              case TemplateRoomChatBubbleItemContent.message(let message) = item.content,
              case let TemplateRoomChatMessageContent.text(text) = message else {
            XCTFail()
            return
        }
        XCTAssertEqual(text.body, newMessage)
    }
}
