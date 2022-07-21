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

class TimelinePollUITests: MockScreenTestCase {
    func testOpenDisclosedPoll() {
        app.goToScreenWithIdentifier(MockTimelinePollScreenState.openDisclosed.title)
        
        XCTAssert(app.staticTexts["Question"].exists)
        XCTAssert(app.staticTexts["20 votes cast"].exists)
        
        XCTAssert(app.buttons["First, 10 votes"].exists)
        XCTAssertEqual(app.buttons["First, 10 votes"].value as! String, "50%")
        
        XCTAssert(app.buttons["Second, 5 votes"].exists)
        XCTAssertEqual(app.buttons["Second, 5 votes"].value as! String, "25%")
        
        XCTAssert(app.buttons["Third, 15 votes"].exists)
        XCTAssertEqual(app.buttons["Third, 15 votes"].value as! String, "75%")
        
        app.buttons["First, 10 votes"].tap()
        
        XCTAssert(app.buttons["First, 11 votes"].exists)
        XCTAssertEqual(app.buttons["First, 11 votes"].value as! String, "55%")
        
        XCTAssert(app.buttons["Second, 4 votes"].exists)
        XCTAssertEqual(app.buttons["Second, 4 votes"].value as! String, "20%")
        
        XCTAssert(app.buttons["Third, 15 votes"].exists)
        XCTAssertEqual(app.buttons["Third, 15 votes"].value as! String, "75%")
        
        app.buttons["Third, 15 votes"].tap()
        
        XCTAssert(app.buttons["First, 10 votes"].exists)
        XCTAssertEqual(app.buttons["First, 10 votes"].value as! String, "50%")
        
        XCTAssert(app.buttons["Second, 4 votes"].exists)
        XCTAssertEqual(app.buttons["Second, 4 votes"].value as! String, "20%")
        
        XCTAssert(app.buttons["Third, 16 votes"].exists)
        XCTAssertEqual(app.buttons["Third, 16 votes"].value as! String, "80%")
    }
    
    func testOpenUndisclosedPoll() {
        app.goToScreenWithIdentifier(MockTimelinePollScreenState.openUndisclosed.title)
        
        XCTAssert(app.staticTexts["Question"].exists)
        XCTAssert(app.staticTexts["20 votes cast"].exists)
        
        XCTAssert(!app.buttons["First, 10 votes"].exists)
        XCTAssert(app.buttons["First"].exists)
        XCTAssertTrue((app.buttons["First"].value as! String).isEmpty)
        
        XCTAssert(!app.buttons["Second, 5 votes"].exists)
        XCTAssert(app.buttons["Second"].exists)
        XCTAssertTrue((app.buttons["Second"].value as! String).isEmpty)
        
        XCTAssert(!app.buttons["Third, 15 votes"].exists)
        XCTAssert(app.buttons["Third"].exists)
        XCTAssertTrue((app.buttons["Third"].value as! String).isEmpty)
        
        app.buttons["First"].tap()
        
        XCTAssert(app.buttons["First"].exists)
        XCTAssert(app.buttons["Second"].exists)
        XCTAssert(app.buttons["Third"].exists)
                
        app.buttons["Third"].tap()
        
        XCTAssert(app.buttons["First"].exists)
        XCTAssert(app.buttons["Second"].exists)
        XCTAssert(app.buttons["Third"].exists)
    }
    
    func testClosedDisclosedPoll() {
        app.goToScreenWithIdentifier(MockTimelinePollScreenState.closedDisclosed.title)
        checkClosedPoll()
    }
    
    func testClosedUndisclosedPoll() {
        app.goToScreenWithIdentifier(MockTimelinePollScreenState.closedUndisclosed.title)
        checkClosedPoll()
    }
    
    private func checkClosedPoll() {
        XCTAssert(app.staticTexts["Question"].exists)
        XCTAssert(app.staticTexts["Final results based on 20 votes"].exists)
        
        XCTAssert(app.buttons["First, 10 votes"].exists)
        XCTAssertEqual(app.buttons["First, 10 votes"].value as! String, "50%")
        
        XCTAssert(app.buttons["Second, 5 votes"].exists)
        XCTAssertEqual(app.buttons["Second, 5 votes"].value as! String, "25%")
        
        XCTAssert(app.buttons["Third, 15 votes"].exists)
        XCTAssertEqual(app.buttons["Third, 15 votes"].value as! String, "75%")
        
        app.buttons["First, 10 votes"].tap()
        
        XCTAssert(app.buttons["First, 10 votes"].exists)
        XCTAssertEqual(app.buttons["First, 10 votes"].value as! String, "50%")
        
        XCTAssert(app.buttons["Second, 5 votes"].exists)
        XCTAssertEqual(app.buttons["Second, 5 votes"].value as! String, "25%")
        
        XCTAssert(app.buttons["Third, 15 votes"].exists)
        XCTAssertEqual(app.buttons["Third, 15 votes"].value as! String, "75%")
    }
}
