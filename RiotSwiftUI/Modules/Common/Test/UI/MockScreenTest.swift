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

/// XCTestCase subclass to ease testing of `MockScreenState`.
/// Creates a test case for each screen state, launches the app,
/// goes to the correct screen and provides the state and key for each
/// invocation of the test.
@available(iOS 14.0, *)
class MockScreenTest: XCTestCase {
    
    enum Constants {
        static let defaultTimeout: TimeInterval = 3
    }
    
    class var screenType: MockScreenState.Type? {
        return nil
    }
    
    class func createTest() -> MockScreenTest {
        return MockScreenTest()
    }
    
    var screenState: MockScreenState?
    var screenStateKey: String?
    let app = XCUIApplication()
        
    override class var defaultTestSuite: XCTestSuite {
        let testSuite = XCTestSuite(name: NSStringFromClass(self))
        guard let screenType = screenType else {
            return testSuite
        }
        
        // Create a test case for each screen state
        screenType.screenStates.enumerated().forEach { index, screenState in
            let key = screenType.screenNames[index]
            addTestFor(screenState: screenState, screenStateKey: key, toTestSuite: testSuite)
        }
        return testSuite
    }
    
    class func addTestFor(screenState: MockScreenState, screenStateKey: String, toTestSuite testSuite: XCTestSuite) {
        let test = createTest()
        test.screenState = screenState
        test.screenStateKey = screenStateKey
        testSuite.addTest(test)
    }
    
    open override func setUpWithError() throws {
        // For every test case launch the app and go to the relevant screen
        continueAfterFailure = false
        app.launch()
        
        guard let screenKey = screenStateKey else { fatalError("no screen") }
        app.goToScreenWithIdentifier(screenKey)
    }
}
