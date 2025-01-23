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

class LocationSharingViewModelTests: XCTestCase {
    var cancellables = Set<AnyCancellable>()
    
    func testInitialState() {
        let viewModel = buildViewModel()
        
        XCTAssertTrue(viewModel.context.viewState.shareButtonEnabled)
        XCTAssertFalse(viewModel.context.viewState.showLoadingIndicator)
        
        XCTAssertNotNil(viewModel.context.viewState.mapStyleURL)
        XCTAssertNotNil(viewModel.context.viewState.userAvatarData)
        
        XCTAssertNil(viewModel.context.viewState.bindings.userLocation)
        XCTAssertNil(viewModel.context.viewState.bindings.alertInfo)
    }
    
    func testCancellation() {
        let viewModel = buildViewModel()
        
        let expectation = expectation(description: "Cancellation completion should be invoked")
        
        viewModel.completion = { result in
            switch result {
            case .share:
                XCTFail()
            case .cancel:
                expectation.fulfill()
            case .shareLiveLocation:
                XCTFail()
            case .checkLiveLocationCanBeStarted:
                XCTFail()
            }
        }
        
        viewModel.context.send(viewAction: .cancel)
        
        waitForExpectations(timeout: 3)
    }
    
    func testShareNoUserLocation() {
        let viewModel = buildViewModel()
        
        XCTAssertNil(viewModel.context.viewState.bindings.userLocation)
        
        viewModel.context.send(viewAction: .share)
        
        XCTAssertNotNil(viewModel.context.viewState.bindings.alertInfo)
        XCTAssertEqual(viewModel.context.viewState.bindings.alertInfo?.id, .userLocatingError)
    }
    
    func testLoading() {
        let viewModel = buildViewModel()
        
        viewModel.startLoading()
        
        XCTAssertFalse(viewModel.context.viewState.shareButtonEnabled)
        XCTAssertTrue(viewModel.context.viewState.showLoadingIndicator)
        
        viewModel.stopLoading()
        
        XCTAssertTrue(viewModel.context.viewState.shareButtonEnabled)
        XCTAssertFalse(viewModel.context.viewState.showLoadingIndicator)
    }
    
    func testInvalidLocationAuthorization() {
        let viewModel = buildViewModel()
        
        viewModel.context.viewState.errorSubject.send(.invalidLocationAuthorization)
        
        XCTAssertNotNil(viewModel.context.alertInfo)
        XCTAssertEqual(viewModel.context.viewState.bindings.alertInfo?.id, .authorizationError)
    }
    
    private func buildViewModel() -> LocationSharingViewModel {
        let service = MockLocationSharingService()
        
        return LocationSharingViewModel(mapStyleURL: URL(string: "http://empty.com")!,
                                        avatarData: AvatarInput(mxContentUri: "", matrixItemId: "", displayName: ""), service: service)
    }
}
