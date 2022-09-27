// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
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

import RiotSwiftUI
import XCTest

class SpaceCreationSettingsUITests: MockScreenTestCase {
    func testPrivateSpace() {
        app.goToScreenWithIdentifier(MockSpaceCreationSettingsScreenState.privateSpace.title)
        
        let addressTextField = app.groups["addressTextField"]
        XCTAssertEqual(addressTextField.exists, false)
    }
    
    func testPublicValidated() {
        app.goToScreenWithIdentifier(MockSpaceCreationSettingsScreenState.validated.title)
        
        let addressTextField = app.groups["addressTextField"]
        XCTAssertEqual(addressTextField.exists, false)
    }
}
