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

class TimelinePollUITests: MockScreenTestCase {
    func testOpenDisclosedPoll() {
        app.goToScreenWithIdentifier(MockTimelinePollScreenState.openDisclosed.title)
        
        XCTAssert(app.staticTexts["Question"].exists)
        XCTAssert(app.staticTexts["20 votes cast"].exists)
        
        XCTAssertEqual(app.staticTexts["PollAnswerOption0Label"].label, "First")
        XCTAssertEqual(app.staticTexts["PollAnswerOption0Count"].label, "10 votes")
        XCTAssertEqual(app.progressIndicators["PollAnswerOption0Progress"].value as? String, "50%")
                
        XCTAssertEqual(app.staticTexts["PollAnswerOption1Label"].label, "Second")
        XCTAssertEqual(app.staticTexts["PollAnswerOption1Count"].label, "5 votes")
        XCTAssertEqual(app.progressIndicators["PollAnswerOption1Progress"].value as? String, "25%")
                
        XCTAssertEqual(app.staticTexts["PollAnswerOption2Label"].label, "Third")
        XCTAssertEqual(app.staticTexts["PollAnswerOption2Count"].label, "15 votes")
        XCTAssertEqual(app.progressIndicators["PollAnswerOption2Progress"].value as? String, "75%")
        
        app.buttons["PollAnswerOption0"].tap()
        
        XCTAssertEqual(app.staticTexts["PollAnswerOption0Label"].label, "First")
        XCTAssertEqual(app.staticTexts["PollAnswerOption0Count"].label, "11 votes")
        XCTAssertEqual(app.progressIndicators["PollAnswerOption0Progress"].value as? String, "55%")
        
        XCTAssertEqual(app.staticTexts["PollAnswerOption1Label"].label, "Second")
        XCTAssertEqual(app.staticTexts["PollAnswerOption1Count"].label, "4 votes")
        XCTAssertEqual(app.progressIndicators["PollAnswerOption1Progress"].value as? String, "20%")
        
        XCTAssertEqual(app.staticTexts["PollAnswerOption2Label"].label, "Third")
        XCTAssertEqual(app.staticTexts["PollAnswerOption2Count"].label, "15 votes")
        XCTAssertEqual(app.progressIndicators["PollAnswerOption2Progress"].value as? String, "75%")
        
        app.buttons["PollAnswerOption2"].tap()
        
        XCTAssertEqual(app.staticTexts["PollAnswerOption0Label"].label, "First")
        XCTAssertEqual(app.staticTexts["PollAnswerOption0Count"].label, "10 votes")
        XCTAssertEqual(app.progressIndicators["PollAnswerOption0Progress"].value as? String, "50%")
        
        XCTAssertEqual(app.staticTexts["PollAnswerOption1Label"].label, "Second")
        XCTAssertEqual(app.staticTexts["PollAnswerOption1Count"].label, "4 votes")
        XCTAssertEqual(app.progressIndicators["PollAnswerOption1Progress"].value as? String, "20%")
        
        XCTAssertEqual(app.staticTexts["PollAnswerOption2Label"].label, "Third")
        XCTAssertEqual(app.staticTexts["PollAnswerOption2Count"].label, "16 votes")
        XCTAssertEqual(app.progressIndicators["PollAnswerOption2Progress"].value as? String, "80%")
    }
    
    func testOpenUndisclosedPoll() {
        app.goToScreenWithIdentifier(MockTimelinePollScreenState.openUndisclosed.title)
        
        XCTAssert(app.staticTexts["Question"].exists)
        XCTAssert(app.staticTexts["20 votes cast"].exists)
        
        XCTAssertEqual(app.staticTexts["PollAnswerOption0Label"].label, "First")
        XCTAssert(!app.staticTexts["PollAnswerOption0Count"].exists)
        XCTAssert(!app.progressIndicators["PollAnswerOption0Progress"].exists)
                
        XCTAssertEqual(app.staticTexts["PollAnswerOption1Label"].label, "Second")
        XCTAssert(!app.staticTexts["PollAnswerOption1Count"].exists)
        XCTAssert(!app.progressIndicators["PollAnswerOption1Progress"].exists)
        
        XCTAssertEqual(app.staticTexts["PollAnswerOption2Label"].label, "Third")
        XCTAssert(!app.staticTexts["PollAnswerOption2Count"].exists)
        XCTAssert(!app.progressIndicators["PollAnswerOption2Progress"].exists)
        
        app.buttons["PollAnswerOption0"].tap()
        
        XCTAssertEqual(app.staticTexts["PollAnswerOption0Label"].label, "First")
        XCTAssertEqual(app.staticTexts["PollAnswerOption1Label"].label, "Second")
        XCTAssertEqual(app.staticTexts["PollAnswerOption2Label"].label, "Third")
                
        app.buttons["PollAnswerOption2"].tap()
        
        XCTAssertEqual(app.staticTexts["PollAnswerOption0Label"].label, "First")
        XCTAssertEqual(app.staticTexts["PollAnswerOption1Label"].label, "Second")
        XCTAssertEqual(app.staticTexts["PollAnswerOption2Label"].label, "Third")
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
                
        XCTAssertEqual(app.staticTexts["PollAnswerOption0Label"].label, "First")
        XCTAssertEqual(app.staticTexts["PollAnswerOption0Count"].label, "10 votes")
        XCTAssertEqual(app.progressIndicators["PollAnswerOption0Progress"].value as? String, "50%")
        
        XCTAssertEqual(app.staticTexts["PollAnswerOption1Label"].label, "Second")
        XCTAssertEqual(app.staticTexts["PollAnswerOption1Count"].label, "5 votes")
        XCTAssertEqual(app.progressIndicators["PollAnswerOption1Progress"].value as? String, "25%")
        
        XCTAssertEqual(app.staticTexts["PollAnswerOption2Label"].label, "Third")
        XCTAssertEqual(app.staticTexts["PollAnswerOption2Count"].label, "15 votes")
        XCTAssertEqual(app.progressIndicators["PollAnswerOption2Progress"].value as? String, "75%")
        
        app.buttons["PollAnswerOption0"].tap()
        
        XCTAssertEqual(app.staticTexts["PollAnswerOption0Label"].label, "First")
        XCTAssertEqual(app.staticTexts["PollAnswerOption0Count"].label, "10 votes")
        XCTAssertEqual(app.progressIndicators["PollAnswerOption0Progress"].value as? String, "50%")
        
        XCTAssertEqual(app.staticTexts["PollAnswerOption1Label"].label, "Second")
        XCTAssertEqual(app.staticTexts["PollAnswerOption1Count"].label, "5 votes")
        XCTAssertEqual(app.progressIndicators["PollAnswerOption1Progress"].value as? String, "25%")
        
        XCTAssertEqual(app.staticTexts["PollAnswerOption2Label"].label, "Third")
        XCTAssertEqual(app.staticTexts["PollAnswerOption2Count"].label, "15 votes")
        XCTAssertEqual(app.progressIndicators["PollAnswerOption2Progress"].value as? String, "75%")
    }
}
