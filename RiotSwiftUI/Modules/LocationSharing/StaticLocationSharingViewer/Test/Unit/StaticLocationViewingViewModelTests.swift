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

class StaticLocationViewingViewModelTests: XCTestCase {
    var cancellables = Set<AnyCancellable>()
    
    func testInitialState() {
        let viewModel = buildViewModel()
        
        XCTAssertTrue(viewModel.context.viewState.shareButtonEnabled)
        XCTAssertFalse(viewModel.context.viewState.showLoadingIndicator)
        
        XCTAssertNotNil(viewModel.context.viewState.mapStyleURL)
        XCTAssertNotNil(viewModel.context.viewState.userAvatarData)
        
        XCTAssertNil(viewModel.context.viewState.bindings.alertInfo)
    }
    
    func testCancellation() {
        let viewModel = buildViewModel()
        
        let expectation = expectation(description: "Cancellation completion should be invoked")
        
        viewModel.completion = { result in
            switch result {
            case .share:
                XCTFail()
            case .close:
                expectation.fulfill()
            }
        }
        
        viewModel.context.send(viewAction: .close)
        
        waitForExpectations(timeout: 3)
    }
    
    func testShareExistingLocation() {
        let viewModel = buildViewModel()
        
        let expectation = expectation(description: "Share completion should be invoked")
        
        viewModel.completion = { result in
            switch result {
            case .share(let coordinate):
                XCTAssertEqual(coordinate.latitude, viewModel.context.viewState.sharedAnnotation.coordinate.latitude)
                XCTAssertEqual(coordinate.longitude, viewModel.context.viewState.sharedAnnotation.coordinate.longitude)
                expectation.fulfill()
            case .close:
                XCTFail()
            }
        }
        
        XCTAssertNotNil(viewModel.context.viewState.sharedAnnotation)
        
        viewModel.context.send(viewAction: .share)
        
        XCTAssertNil(viewModel.context.viewState.bindings.alertInfo)
        
        waitForExpectations(timeout: 3)
    }
    
    func testToggleShowUserLocation() {
        let viewModel = buildViewModel()
        XCTAssertEqual(viewModel.context.viewState.showsUserLocationMode, .hide)
        viewModel.context.send(viewAction: .showUserLocation)
        XCTAssertEqual(viewModel.context.viewState.showsUserLocationMode, .follow)
    }
    
    private func buildViewModel() -> StaticLocationViewingViewModel {
        StaticLocationViewingViewModel(mapStyleURL: URL(string: "http://empty.com")!,
                                       avatarData: AvatarInput(mxContentUri: "", matrixItemId: "", displayName: ""),
                                       location: CLLocationCoordinate2D(latitude: 51.4932641, longitude: -0.257096),
                                       coordinateType: .user,
                                       service: MockStaticLocationSharingViewerService())
    }
}
