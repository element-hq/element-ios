// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationPostProcess SpaceCreationPostProcess
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
class SpaceCreationPostProcessUITests: MockScreenTest {

    override class var screenType: MockScreenState.Type {
        return MockSpaceCreationPostProcessScreenState.self
    }

    override class func createTest() -> MockScreenTest {
        return SpaceCreationPostProcessUITests(selector: #selector(verifySpaceCreationPostProcessScreen))
    }

    func verifySpaceCreationPostProcessScreen() throws {
        guard let screenState = screenState as? MockSpaceCreationPostProcessScreenState else { fatalError("no screen") }
        switch screenState {
        case .presence(let presence):
            verifySpaceCreationPostProcessPresence(presence: presence)
        case .longDisplayName(let name):
            verifySpaceCreationPostProcessLongName(name: name)
        }
    }

    func verifySpaceCreationPostProcessPresence(presence: SpaceCreationPostProcessPresence) {
        let presenceText = app.staticTexts["presenceText"]
        XCTAssert(presenceText.exists)
        XCTAssertEqual(presenceText.label, presence.title)
    }

    func verifySpaceCreationPostProcessLongName(name: String) {
        let displayNameText = app.staticTexts["displayNameText"]
        XCTAssert(displayNameText.exists)
        XCTAssertEqual(displayNameText.label, name)
    }

}
