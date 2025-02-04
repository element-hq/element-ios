//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import RiotSwiftUI

class AuthenticationServerSelectionViewModelTests: XCTestCase {
    private enum Constants {
        static let counterInitialValue = 0
    }
    
    var viewModel: AuthenticationServerSelectionViewModelProtocol!
    var context: AuthenticationServerSelectionViewModelType.Context!
    
    override func setUp() {
        viewModel = AuthenticationServerSelectionViewModel(homeserverAddress: "", flow: .login, hasModalPresentation: true)
        context = viewModel.context
    }

    @MainActor func testErrorMessage() async throws {
        // Given a new instance of the view model.
        XCTAssertNil(context.viewState.footerError, "There should not be an error message for a new view model.")
        XCTAssertFalse(context.viewState.isShowingFooterError, "There should not be an error shown.")
        
        // When an error occurs.
        let message = "Unable to contact server."
        viewModel.displayError(.footerMessage(message))
        
        // Then the footer should now be showing an error.
        XCTAssertEqual(context.viewState.footerError, .message(message), "The error message should be stored.")
        XCTAssertTrue(context.viewState.isShowingFooterError, "There should be an error shown.")
        
        // And when clearing the error.
        context.send(viewAction: .clearFooterError)
        
        // Wait for the action to spawn a Task on the main actor as the Context protocol doesn't support actors.
        await Task.yield()
        
        // Then the error message should now be removed.
        XCTAssertNil(context.viewState.footerError, "The error message should have been cleared.")
        XCTAssertFalse(context.viewState.isShowingFooterError, "There should not be an error shown anymore.")
    }
    
    @MainActor func testSunsetBanner() async throws {
        // Given a new instance of the view model.
        XCTAssertNil(context.viewState.footerError, "There should not be an error for a new view model.")
        XCTAssertFalse(context.viewState.isShowingFooterError, "There should not be an error shown.")
        
        // When an error occurs.
        let message = "Unable to contact server."
        viewModel.displayError(.requiresReplacementApp)
        
        // Then the footer should now be showing an error.
        XCTAssertEqual(context.viewState.footerError, .sunsetBanner, "The banner should be shown.")
        XCTAssertTrue(context.viewState.isShowingFooterError, "There should be an error shown.")
        
        // And when clearing the error.
        context.send(viewAction: .clearFooterError)
        
        // Wait for the action to spawn a Task on the main actor as the Context protocol doesn't support actors.
        await Task.yield()
        
        // Then the error message should now be removed.
        XCTAssertNil(context.viewState.footerError, "The error should have been cleared.")
        XCTAssertFalse(context.viewState.isShowingFooterError, "There should not be an error shown anymore.")
    }
}
