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
import RiotSwiftUI

@available(iOS 14.0, *)
class StaticLocationViewingUITests: MockScreenTest {
    
    override class var screenType: MockScreenState.Type {
        return MockStaticLocationViewingScreenState.self
    }

    override class func createTest() -> MockScreenTest {
        return StaticLocationViewingUITests(selector: #selector(verifyStaticLocationViewingScreen))
    }

    func verifyStaticLocationViewingScreen() {
        guard let screenState = screenState as? MockStaticLocationViewingScreenState else { fatalError("no screen") }
        
        switch screenState {
        case .showUserLocation:
            verifyInitialExistingLocation()
        case .showPinLocation:
            verifyInitialExistingLocation()
        }
    }
    
    func verifyInitialExistingLocation() {
        XCTAssertTrue(app.buttons["Cancel"].exists, "The cancel button should exist.")
        XCTAssertTrue(app.buttons["shareButton"].exists, "The share button should exist.")
    }
}
