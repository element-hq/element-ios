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

import Combine
import XCTest

@testable import RiotSwiftUI

class OnboardingDisplayNameViewModelTests: XCTestCase {
    var viewModel: OnboardingDisplayNameViewModel!
    var context: OnboardingDisplayNameViewModelType.Context!
    
    override func setUpWithError() throws {
        viewModel = nil
        context = nil
    }
    
    func setUp(with displayName: String) {
        viewModel = OnboardingDisplayNameViewModel(displayName: displayName)
        context = viewModel.context
    }

    func testValidDisplayName() {
        // Given a short display name
        let displayName = "Alice"
        setUp(with: displayName)
        
        // When validating the display name
        viewModel.process(viewAction: .validateDisplayName)
        
        // Then no error message should be set
        XCTAssertEqual(context.viewState.bindings.displayName, displayName, "The display name should match the value used at init.")
        XCTAssertNil(context.viewState.validationErrorMessage, "There should not be an error message in the view state.")
    }
    
    func testInvalidDisplayName() {
        // Given a short display name
        let displayName = """
        Bacon ipsum dolor amet filet mignon chicken kevin andouille. Doner shoulder beef, brisket bresaola turkey jowl venison. Ham hock cow turducken, chislic venison doner short loin strip steak tri-tip jowl. Sirloin pork belly hamburger ribeye. Tail capicola alcatra short ribs turkey doner.
        """
        setUp(with: displayName)
        
        // When validating the display name
        viewModel.process(viewAction: .validateDisplayName)
        
        // Then no error message should be set
        XCTAssertEqual(context.viewState.bindings.displayName, displayName, "The display name should match the value used at init.")
        XCTAssertNotNil(context.viewState.validationErrorMessage, "There should be an error message in the view state.")
    }
}
