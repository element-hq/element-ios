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
@testable import Element

class MockRoomNotificationSettingsView: RoomNotificationSettingsViewModelViewDelegate {
    
    var viewState: RoomNotificationSettingsViewStateType?
    
    func roomNotificationSettingsViewModel(_ viewModel: RoomNotificationSettingsViewModelType, didUpdateViewState viewState: RoomNotificationSettingsViewStateType) {
        self.viewState = viewState
    }
}

class MockRoomNotificationSettingsCoordinator: RoomNotificationSettingsViewModelCoordinatorDelegate {
    
    var didComplete = false
    var didCancel = false
    func roomNotificationSettingsViewModelDidComplete(_ viewModel: RoomNotificationSettingsViewModelType) {
        didComplete = true
    }
    
    func roomNotificationSettingsViewModelDidCancel(_ viewModel: RoomNotificationSettingsViewModelType) {
        didCancel = true
    }
}

class RoomNotificationSettingsViewModelTests: XCTestCase {
    
    enum Constants{
        static let roomDisplayName: String = "Test Room Name"
        static let roomId: String = "1"
        static let avatarUrl: String = "http://test.url.com"
        static let avatarData = RoomAvatarViewData(roomId: "1", displayName: roomDisplayName, avatarUrl: avatarUrl, mediaManager: MXMediaManager())
    }
    
    var coordinator: MockRoomNotificationSettingsCoordinator!
    var service: MockRoomNotificationSettingsService!
    var view: MockRoomNotificationSettingsView!
    var viewModel: RoomNotificationSettingsViewModel!
    
    override func setUpWithError() throws {
        service = MockRoomNotificationSettingsService(initialState: .all)
        view = MockRoomNotificationSettingsView()
        coordinator = MockRoomNotificationSettingsCoordinator()
    }
    
    func setupViewModel(roomEncrypted: Bool, showAvatar: Bool) {
        let avatarData: AvatarProtocol? = showAvatar ? Constants.avatarData : nil
        let viewModel = RoomNotificationSettingsViewModel(roomNotificationService: service, avatarData: avatarData, displayName: Constants.roomDisplayName, roomEncrypted: roomEncrypted)
        viewModel.viewDelegate = view
        viewModel.coordinatorDelegate = coordinator
        self.viewModel = viewModel
    }
    
    func testUnloaded() throws {
        setupViewModel(roomEncrypted: true, showAvatar: false)
        XCTAssertNil(view.viewState)
    }
        
    func testUnencryptedOptions() throws {
        setupViewModel(roomEncrypted: false, showAvatar: false)
        viewModel.process(viewAction: .load)
        XCTAssertNotNil(view.viewState)
        XCTAssertTrue(view.viewState!.notificationOptions.count == 3)
    }
    
    func testEncryptedOptions() throws {
        setupViewModel(roomEncrypted: true, showAvatar: false)
        viewModel.process(viewAction: .load)
        XCTAssertNotNil(view.viewState)
        XCTAssertTrue(view.viewState!.notificationOptions.count == 2)
    }

    func testAvatar() throws {
        setupViewModel(roomEncrypted: true, showAvatar: true)
        viewModel.process(viewAction: .load)
        guard let avatarData = view.viewState?.avatarData as? RoomAvatarViewData else {
            XCTFail()
            return
        }
        XCTAssertEqual(avatarData.avatarUrl, Constants.avatarUrl)
    }

    func testSelectionUpdateAndSave() throws {
        setupViewModel(roomEncrypted: false, showAvatar: false)
        viewModel.process(viewAction: .load)
        XCTAssertNotNil(view.viewState)
        XCTAssertTrue(view.viewState!.notificationState == .all)
        viewModel.process(viewAction: .selectNotificationState(.mentionsAndKeywordsOnly))
        XCTAssertTrue(view.viewState!.notificationState == .mentionsAndKeywordsOnly)
        viewModel.process(viewAction: .save)
        XCTAssertTrue(service.notificationState == .mentionsAndKeywordsOnly)
        XCTAssertTrue(coordinator.didComplete)
    }
    
    func testCancel() throws {
        setupViewModel(roomEncrypted: false, showAvatar: false)
        viewModel.process(viewAction: .load)
        XCTAssertNotNil(view.viewState)
        viewModel.process(viewAction: .cancel)
        XCTAssertTrue(coordinator.didCancel)
    }
    
    func testMentionsOnlyNotAvaileOnEncryptedRoom() throws {
        service = MockRoomNotificationSettingsService(initialState: .mentionsAndKeywordsOnly)
        setupViewModel(roomEncrypted: true, showAvatar: false)
        
        viewModel.process(viewAction: .load)
        XCTAssertNotNil(view.viewState)
        XCTAssertTrue(view.viewState!.notificationState == .mute)
    }
    
}
