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
