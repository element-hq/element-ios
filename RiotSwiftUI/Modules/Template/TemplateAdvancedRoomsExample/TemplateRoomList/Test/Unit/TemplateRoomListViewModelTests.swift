//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

@testable import RiotSwiftUI

class TemplateRoomListViewModelTests: XCTestCase {
    private enum Constants { }

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
        service.simulateUpdate(rooms: updatedRooms)
        XCTAssertEqual(try awaitDeferred(), [MockTemplateRoomListService.mockRooms, updatedRooms])
    }
}
