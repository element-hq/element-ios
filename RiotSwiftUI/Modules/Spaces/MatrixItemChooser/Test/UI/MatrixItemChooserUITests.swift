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
class MatrixItemChooserUITests: MockScreenTest {

    override class var screenType: MockScreenState.Type {
        return MockMatrixItemChooserScreenState.self
    }

    override class func createTest() -> MockScreenTest {
        return MatrixItemChooserUITests(selector: #selector(verifyMatrixItemChooserScreen))
    }

    func verifyMatrixItemChooserScreen() throws {
        guard let screenState = screenState as? MockMatrixItemChooserScreenState else { fatalError("no screen") }
        switch screenState {
        case .noItems:
            verifyEmptyScreen()
        case .items:
            verifyPopulatedScreen()
        case .selectedItems:
            verifyPopulatedWithSelectionScreen()
        case .selectionHeader:
            break
        }
    }
    
    func verifyEmptyScreen() {
        XCTAssertEqual(app.staticTexts["titleText"].label, VectorL10n.spacesCreationAddRoomsTitle)
        XCTAssertEqual(app.staticTexts["messageText"].label, VectorL10n.spacesCreationAddRoomsMessage)
        XCTAssertEqual(app.staticTexts["emptyListMessage"].exists, true)
        XCTAssertEqual(app.staticTexts["emptyListMessage"].label, VectorL10n.spacesNoResultFoundTitle)
    }

    func verifyPopulatedScreen() {
        XCTAssertEqual(app.staticTexts["titleText"].label, VectorL10n.spacesCreationAddRoomsTitle)
        XCTAssertEqual(app.staticTexts["messageText"].label, VectorL10n.spacesCreationAddRoomsMessage)
        XCTAssertEqual(app.staticTexts["emptyListMessage"].exists, false)
    }

    func verifyPopulatedWithSelectionScreen() {
        XCTAssertEqual(app.staticTexts["titleText"].label, VectorL10n.spacesCreationAddRoomsTitle)
        XCTAssertEqual(app.staticTexts["messageText"].label, VectorL10n.spacesCreationAddRoomsMessage)
        XCTAssertEqual(app.staticTexts["emptyListMessage"].exists, false)
    }

}
