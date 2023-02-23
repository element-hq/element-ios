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
