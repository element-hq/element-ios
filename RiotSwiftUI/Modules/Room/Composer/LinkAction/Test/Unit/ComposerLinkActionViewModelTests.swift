//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@testable import RiotSwiftUI
import WysiwygComposer
import XCTest

final class ComposerLinkActionViewModelTests: XCTestCase {
    var viewModel: ComposerLinkActionViewModel!
    var context: ComposerLinkActionViewModel.Context!
    
    override func setUpWithError() throws {
        viewModel = nil
        context = nil
    }
    
    private func setUp(with linkAction: LinkAction) {
        viewModel = ComposerLinkActionViewModel(from: linkAction)
        context = viewModel.context
    }
    
    func testCreateWithTextDefaultState() {
        setUp(with: .createWithText)
        XCTAssertEqual(context.viewState.bindings.text, "")
        XCTAssertEqual(context.viewState.bindings.linkUrl, "")
        XCTAssertTrue(context.viewState.isSaveButtonDisabled)
        XCTAssertFalse(context.viewState.shouldDisplayRemoveButton)
        XCTAssertTrue(context.viewState.shouldDisplayTextField)
        XCTAssertEqual(context.viewState.title, VectorL10n.wysiwygComposerLinkActionCreateTitle)
    }
    
    func testCreateDefaultState() {
        setUp(with: .create)
        XCTAssertEqual(context.viewState.bindings.text, "")
        XCTAssertEqual(context.viewState.bindings.linkUrl, "")
        XCTAssertTrue(context.viewState.isSaveButtonDisabled)
        XCTAssertFalse(context.viewState.shouldDisplayRemoveButton)
        XCTAssertFalse(context.viewState.shouldDisplayTextField)
        XCTAssertEqual(context.viewState.title, VectorL10n.wysiwygComposerLinkActionCreateTitle)
    }
    
    func testEditDefaultState() {
        let link = "element.io"
        setUp(with: .edit(url: link))
        XCTAssertEqual(context.viewState.bindings.text, "")
        XCTAssertEqual(context.viewState.bindings.linkUrl, link)
        XCTAssertTrue(context.viewState.isSaveButtonDisabled)
        XCTAssertTrue(context.viewState.shouldDisplayRemoveButton)
        XCTAssertFalse(context.viewState.shouldDisplayTextField)
        XCTAssertEqual(context.viewState.title, VectorL10n.wysiwygComposerLinkActionEditTitle)
    }
    
    func testTextNotEmptyCheck() {
        setUp(with: .createWithText)
        XCTAssertTrue(context.viewState.isSaveButtonDisabled)
        context.linkUrl = "element.io"
        XCTAssertTrue(context.viewState.isSaveButtonDisabled)
        context.text = "text"
        XCTAssertFalse(context.viewState.isSaveButtonDisabled)
    }
    
    func testCancelAction() {
        setUp(with: .create)
        var result: ComposerLinkActionViewModelResult!
        viewModel.callback = { value in
            result = value
        }
        context.send(viewAction: .cancel)
        XCTAssertEqual(result, .cancel)
    }
    
    func testRemoveAction() {
        setUp(with: .edit(url: "element.io"))
        var result: ComposerLinkActionViewModelResult!
        viewModel.callback = { value in
            result = value
        }
        context.send(viewAction: .remove)
        XCTAssertEqual(result, .performOperation(.removeLinks))
    }
    
    func testSaveActionForCreate() {
        setUp(with: .create)
        var result: ComposerLinkActionViewModelResult!
        viewModel.callback = { value in
            result = value
        }
        let link = "element.io"
        context.linkUrl = link
        context.send(viewAction: .save)
        XCTAssertEqual(result, .performOperation(.setLink(urlString: link)))
    }
    
    func testSaveActionForCreateWithText() {
        setUp(with: .createWithText)
        var result: ComposerLinkActionViewModelResult!
        viewModel.callback = { value in
            result = value
        }
        let link = "element.io"
        context.linkUrl = link
        let text = "test"
        context.text = text
        context.send(viewAction: .save)
        XCTAssertEqual(result, .performOperation(.createLink(urlString: link, text: text)))
    }
    
    func testSaveActionForEdit() {
        setUp(with: .edit(url: "element.io"))
        var result: ComposerLinkActionViewModelResult!
        viewModel.callback = { value in
            result = value
        }
        XCTAssertTrue(context.viewState.isSaveButtonDisabled)
        let link = "matrix.org"
        context.linkUrl = link
        XCTAssertFalse(context.viewState.isSaveButtonDisabled)
        context.send(viewAction: .save)
        XCTAssertEqual(result, .performOperation(.setLink(urlString: link)))
    }
}
