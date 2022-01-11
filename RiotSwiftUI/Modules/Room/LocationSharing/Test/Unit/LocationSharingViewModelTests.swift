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
import CoreLocation

@testable import RiotSwiftUI

@available(iOS 14.0, *)
class LocationSharingViewModelTests: XCTestCase {
    
    var cancellables = Set<AnyCancellable>()
    
    func testInitialState() {
        let viewModel = buildViewModel(withLocation: false)
        
        XCTAssertTrue(viewModel.context.viewState.shareButtonEnabled)
        XCTAssertTrue(viewModel.context.viewState.shareButtonVisible)
        XCTAssertFalse(viewModel.context.viewState.showLoadingIndicator)
        
        XCTAssertNotNil(viewModel.context.viewState.tileServerMapURL)
        XCTAssertNotNil(viewModel.context.viewState.avatarData)
        
        XCTAssertNil(viewModel.context.viewState.location)
        XCTAssertNil(viewModel.context.viewState.bindings.userLocation)
        XCTAssertNil(viewModel.context.viewState.bindings.alertInfo)
    }
    
    func testCancellation() {
        let viewModel = buildViewModel(withLocation: false)
        
        let expectation = self.expectation(description: "Cancellation completion should be invoked")
        
        viewModel.completion = { result in
            switch result {
            case .share:
                XCTFail()
            case .cancel:
                expectation.fulfill()
            }
        }
        
        viewModel.context.send(viewAction: .cancel)
        
        waitForExpectations(timeout: 3)
    }
    
    func testShareNoUserLocation() {
        let viewModel = buildViewModel(withLocation: false)
        
        XCTAssertNil(viewModel.context.viewState.bindings.userLocation)
        XCTAssertNil(viewModel.context.viewState.location)
        
        viewModel.context.send(viewAction: .share)
        
        XCTAssertNotNil(viewModel.context.viewState.bindings.alertInfo)
        XCTAssertEqual(viewModel.context.viewState.bindings.alertInfo?.id, .userLocatingError)
    }
    
    func testShareExistingLocation() {
        let viewModel = buildViewModel(withLocation: true)
        
        let expectation = self.expectation(description: "Share completion should be invoked")
        
        viewModel.completion = { result in
            switch result {
            case .share(let latitude, let longitude):
                XCTAssertEqual(latitude, viewModel.context.viewState.location?.latitude)
                XCTAssertEqual(longitude, viewModel.context.viewState.location?.longitude)
                expectation.fulfill()
            case .cancel:
                XCTFail()
            }
        }
        
        XCTAssertNil(viewModel.context.viewState.bindings.userLocation)
        XCTAssertNotNil(viewModel.context.viewState.location)
        
        viewModel.context.send(viewAction: .share)
        
        XCTAssertNil(viewModel.context.viewState.bindings.alertInfo)
        
        waitForExpectations(timeout: 3)
    }
    
    func testLoading() {
        let viewModel = buildViewModel(withLocation: false)
        
        viewModel.dispatch(action: .startLoading)
        
        XCTAssertFalse(viewModel.context.viewState.shareButtonEnabled)
        XCTAssertTrue(viewModel.context.viewState.showLoadingIndicator)
        
        viewModel.dispatch(action: .stopLoading(nil))
        
        XCTAssertTrue(viewModel.context.viewState.shareButtonEnabled)
        XCTAssertFalse(viewModel.context.viewState.showLoadingIndicator)
    }
    
    func testInvalidLocationAuthorization() {
        let viewModel = buildViewModel(withLocation: false)
        
        viewModel.context.viewState.errorSubject.send(.invalidLocationAuthorization)
        
        XCTAssertNotNil(viewModel.context.alertInfo)
        XCTAssertEqual(viewModel.context.viewState.bindings.alertInfo?.id, .authorizationError)
    }
    
    private func buildViewModel(withLocation: Bool) -> LocationSharingViewModel {
        LocationSharingViewModel(tileServerMapURL: URL(string: "http://empty.com")!,
                                                 avatarData: AvatarInput(mxContentUri: "", matrixItemId: "", displayName: ""),
                                                 location: (withLocation ? CLLocationCoordinate2D(latitude: 51.4932641, longitude: -0.257096) : nil))
    }
}
