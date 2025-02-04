//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import CoreLocation
import XCTest

@testable import RiotSwiftUI

class LiveLocationSharingViewerViewModelTests: XCTestCase {
    var service: MockLiveLocationSharingViewerService!
    var viewModel: LiveLocationSharingViewerViewModelProtocol!
    var context: LiveLocationSharingViewerViewModelType.Context!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        service = MockLiveLocationSharingViewerService()
        viewModel = LiveLocationSharingViewerViewModel(mapStyleURL: BuildSettings.defaultTileServerMapStyleURL, service: service)
        context = viewModel.context
    }
    
    func testIsUserBeingShared() {
        XCTAssertTrue(context.viewState.isCurrentUserShared)
    }
    
    func testToggleShowUserLocation() {
        let service = MockLiveLocationSharingViewerService(currentUserSharingLocation: false)
        let viewModel = LiveLocationSharingViewerViewModel(mapStyleURL: BuildSettings.defaultTileServerMapStyleURL, service: service)
        XCTAssertFalse(viewModel.context.viewState.isCurrentUserShared)
        XCTAssertEqual(viewModel.context.viewState.showsUserLocationMode, .hide)
        viewModel.context.send(viewAction: .showUserLocation)
        XCTAssertEqual(viewModel.context.viewState.showsUserLocationMode, .follow)
        viewModel.context.send(viewAction: .tapListItem("@bob:matrix.org"))
        XCTAssertEqual(viewModel.context.viewState.showsUserLocationMode, .show)
    }
}
