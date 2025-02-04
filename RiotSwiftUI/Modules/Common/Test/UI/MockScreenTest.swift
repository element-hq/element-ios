//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
