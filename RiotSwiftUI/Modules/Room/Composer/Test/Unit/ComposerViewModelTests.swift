//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
    
    func testSelectionToRestore() {
        XCTAssertEqual(viewModel.selectionToRestore, nil)
        let testRange = NSRange(location: 0, length: 10)
        context.send(viewAction: .storeSelection(selection: testRange))
        XCTAssertEqual(viewModel.selectionToRestore, testRange)
    }
    
    func testLinkAction() {
        var result: ComposerViewModelResult!
        viewModel.callback = { value in
            result = value
        }
        context.send(viewAction: .linkTapped(linkAction: .createWithText))
        XCTAssertEqual(result, .linkTapped(LinkAction: .createWithText))
        context.send(viewAction: .linkTapped(linkAction: .create))
        XCTAssertEqual(result, .linkTapped(LinkAction: .create))
        context.send(viewAction: .linkTapped(linkAction: .edit(url: "https://element.io")))
        XCTAssertEqual(result, .linkTapped(LinkAction: .edit(url: "https://element.io")))
    }
}
