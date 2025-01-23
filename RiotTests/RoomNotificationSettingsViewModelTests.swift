// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
