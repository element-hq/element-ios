//
// Copyright 2022 New Vector Ltd
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

@testable import RiotSwiftUI
import SwiftUI
import XCTest

final class ComposerViewModelTests: XCTestCase {
    var viewModel: ComposerViewModel!
    var context: ComposerViewModel.Context!
    
    override func setUpWithError() throws {
        viewModel = ComposerViewModel(
            initialViewState: ComposerViewState(
                textFormattingEnabled: true,
                isLandscapePhone: false,
                bindings: ComposerBindings(focused: false)
            )
        )
        context = viewModel.context
    }
    
    func testSendState() {
        viewModel.sendMode = .send
        XCTAssert(context.viewState.sendMode == .send)
        XCTAssert(context.viewState.shouldDisplayContext == false)
        XCTAssert(context.viewState.eventSenderDisplayName == nil)
        XCTAssert(context.viewState.contextImageName == nil)
        XCTAssert(context.viewState.contextDescription == nil)
    }
    
    func testEditState() {
        viewModel.sendMode = .edit
        XCTAssert(context.viewState.sendMode == .edit)
        XCTAssert(context.viewState.shouldDisplayContext == true)
        XCTAssert(context.viewState.eventSenderDisplayName == nil)
        XCTAssert(context.viewState.contextImageName == Asset.Images.inputEditIcon.name)
        XCTAssert(context.viewState.contextDescription == VectorL10n.roomMessageEditing)
    }
    
    func testReplyState() {
        viewModel.eventSenderDisplayName = "TestUser"
        viewModel.sendMode = .reply
        XCTAssert(context.viewState.sendMode == .reply)
        XCTAssert(context.viewState.shouldDisplayContext == true)
        XCTAssert(context.viewState.eventSenderDisplayName == "TestUser")
        XCTAssert(context.viewState.contextImageName == Asset.Images.inputReplyIcon.name)
        XCTAssert(context.viewState.contextDescription == VectorL10n.roomMessageReplyingTo("TestUser"))
    }
    
    func testCancelTapped() {
        var result: ComposerViewModelResult!
        viewModel.callback = { value in
            result = value
        }
        context.send(viewAction: .cancel)
        XCTAssert(result == .cancel)
    }
    
    func testPlaceholder() {
        XCTAssert(context.viewState.placeholder == nil)
        viewModel.placeholder = "Placeholder Test"
        XCTAssert(context.viewState.placeholder == "Placeholder Test")
    }
    
    func testDimissKeyboard() {
        viewModel.state.bindings.focused = true
        viewModel.dismissKeyboard()
        XCTAssert(context.viewState.bindings.focused == false)
    }
}
