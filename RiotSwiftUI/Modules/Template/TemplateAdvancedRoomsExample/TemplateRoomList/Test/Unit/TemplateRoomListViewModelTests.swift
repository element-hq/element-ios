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

import XCTest
import Combine

@testable import RiotSwiftUI

class TemplateRoomListViewModelTests: XCTestCase {
    private enum Constants {
    }
    var service: MockTemplateRoomListService!
    var viewModel: TemplateRoomListViewModel!
    var context: TemplateRoomListViewModel.Context!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        service = MockTemplateRoomListService()
        viewModel = TemplateRoomListViewModel(templateRoomListService: service)
        context = viewModel.context
    }
    
    func testInitialState() {
        XCTAssertEqual(context.viewState.rooms, MockTemplateRoomListService.mockRooms)
    }

    func testFirstValueReceived() throws {
        let roomsPublisher = context.$viewState.map(\.rooms).removeDuplicates().collect(1).first()
        XCTAssertEqual(try xcAwait(roomsPublisher), [MockTemplateRoomListService.mockRooms])
    }
    
    func testUpdatesReceived() throws {
        let updatedRooms = Array(MockTemplateRoomListService.mockRooms.dropLast())
        let roomsPublisher = context.$viewState.map(\.rooms).removeDuplicates().collect(2).first()
        let awaitDeferred = xcAwaitDeferred(roomsPublisher)
        service.simulateUpdate(rooms:  updatedRooms)
        XCTAssertEqual(try awaitDeferred(), [MockTemplateRoomListService.mockRooms, updatedRooms])
    }
}
