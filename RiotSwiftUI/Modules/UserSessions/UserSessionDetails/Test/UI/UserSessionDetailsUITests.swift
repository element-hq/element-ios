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

class UserSessionDetailsUITests: MockScreenTestCase {
    func test_longPressDetailsCell_CopiesValueToClipboard() throws {
        app.goToScreenWithIdentifier(MockUserSessionDetailsScreenState.allSections.title)
        
        UIPasteboard.general.string = ""
        
        let tables = app.tables
        let sessionNameIosCell = tables.cells["Session name, iOS"]
        sessionNameIosCell.press(forDuration: 0.5)
        
        app.buttons["Copy"].tap()
        
        let clipboard = try XCTUnwrap(UIPasteboard.general.string)
        XCTAssertEqual(clipboard, "iOS")
    }
}
