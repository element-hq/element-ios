//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

@testable import RiotSwiftUI

class TemplateUserProfileViewModelTests: XCTestCase {
    private enum Constants {
        static let presenceInitialValue: TemplateUserProfilePresence = .offline
        static let displayName = "Alice"
    }

    var service: MockTemplateUserProfileService!
    var viewModel: TemplateUserProfileViewModelProtocol!
    var context: TemplateUserProfileViewModelType.Context!
    var cancellables = Set<AnyCancellable>()
    override func setUpWithError() throws {
        service = MockTemplateUserProfileService(displayName: Constants.displayName, presence: Constants.presenceInitialValue)
        viewModel = TemplateUserProfileViewModel.makeTemplateUserProfileViewModel(templateUserProfileService: service)
        context = viewModel.context
    }

    func testInitialState() {
        XCTAssertEqual(context.viewState.displayName, Constants.displayName)
        XCTAssertEqual(context.viewState.presence, Constants.presenceInitialValue)
    }

    func testFirstPresenceReceived() throws {
        let presencePublisher = context.$viewState.map(\.presence).removeDuplicates().collect(1).first()
        XCTAssertEqual(try xcAwait(presencePublisher), [Constants.presenceInitialValue])
    }

    func testPresenceUpdatesReceived() throws {
        let presencePublisher = context.$viewState.map(\.presence).removeDuplicates().collect(3).first()
        let awaitDeferred = xcAwaitDeferred(presencePublisher)
        let newPresenceValue1: TemplateUserProfilePresence = .online
        let newPresenceValue2: TemplateUserProfilePresence = .idle
        service.simulateUpdate(presence: newPresenceValue1)
        service.simulateUpdate(presence: newPresenceValue2)
        XCTAssertEqual(try awaitDeferred(), [Constants.presenceInitialValue, newPresenceValue1, newPresenceValue2])
    }
}
