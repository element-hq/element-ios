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

/// XCTestCase subclass to ease testing of `MockScreenState`.
/// Launches the app with an environment variable used to disable animations.
/// Begin each test with the following code before checking the UI:
/// ```
/// app.goToScreenWithIdentifier(MockTemplateScreenState.someScreenState.title)
/// ```
class MockScreenTestCase: XCTestCase {
    let app = XCUIApplication()
    
    override open func setUpWithError() throws {
        app.launchEnvironment = ["IS_RUNNING_UI_TESTS": "1"]
        app.launch()
    }
}
