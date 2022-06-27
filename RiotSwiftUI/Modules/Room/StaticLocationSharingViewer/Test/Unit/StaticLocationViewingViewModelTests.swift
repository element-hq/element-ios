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
        
        let expectation = self.expectation(description: "Cancellation completion should be invoked")
        
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
        
        let expectation = self.expectation(description: "Share completion should be invoked")
        
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
    
    private func buildViewModel() -> StaticLocationViewingViewModel {
        StaticLocationViewingViewModel(mapStyleURL: URL(string: "http://empty.com")!,
                                       avatarData: AvatarInput(mxContentUri: "", matrixItemId: "", displayName: ""),
                                       location: CLLocationCoordinate2D(latitude: 51.4932641, longitude: -0.257096),
                                       coordinateType: .user)
    }
}
