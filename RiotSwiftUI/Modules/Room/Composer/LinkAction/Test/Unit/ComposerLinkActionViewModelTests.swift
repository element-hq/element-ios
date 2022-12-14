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
        let link = "https://element.io"
        setUp(with: .edit(link: link))
        XCTAssertEqual(context.viewState.bindings.text, "")
        XCTAssertEqual(context.viewState.bindings.linkUrl, link)
        XCTAssertFalse(context.viewState.isSaveButtonDisabled)
        XCTAssertTrue(context.viewState.shouldDisplayRemoveButton)
        XCTAssertFalse(context.viewState.shouldDisplayTextField)
        XCTAssertEqual(context.viewState.title, VectorL10n.wysiwygComposerLinkActionEditTitle)
    }
    
    func testUrlValidityCheck() {
        setUp(with: .create)
        XCTAssertTrue(context.viewState.isSaveButtonDisabled)
        context.linkUrl = "invalid url"
        XCTAssertTrue(context.viewState.isSaveButtonDisabled)
        context.linkUrl = "https://element.io"
        XCTAssertFalse(context.viewState.isSaveButtonDisabled)
    }
    
    func testTextNotEmptyCheck() {
        setUp(with: .createWithText)
        XCTAssertTrue(context.viewState.isSaveButtonDisabled)
        context.linkUrl = "https://element.io"
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
        setUp(with: .edit(link: "https://element.io"))
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
        let link = "https://element.io"
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
        let link = "https://element.io"
        context.linkUrl = link
        let text = "test"
        context.text = text
        context.send(viewAction: .save)
        XCTAssertEqual(result, .performOperation(.createLink(urlString: link, text: text)))
    }
    
    func testSaveActionForEdit() {
        setUp(with: .edit(link: "https://element.io"))
        var result: ComposerLinkActionViewModelResult!
        viewModel.callback = { value in
            result = value
        }
        let link = "https://matrix.org"
        context.linkUrl = link
        context.send(viewAction: .save)
        XCTAssertEqual(result, .performOperation(.setLink(urlString: link)))
    }
}
