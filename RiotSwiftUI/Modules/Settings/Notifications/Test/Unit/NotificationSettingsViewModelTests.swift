//
// Copyright 2023 New Vector Ltd
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
import XCTest

final class NotificationSettingsViewModelTests: XCTestCase {
    private var viewModel: NotificationSettingsViewModel!
    private var notificationService: MockNotificationSettingsService!

    override func setUpWithError() throws {
        notificationService = .init()
    }

    func testAllTheRulesAreChecked() throws {
        viewModel = .init(notificationSettingsService: notificationService, ruleIds: .default)
        
        XCTAssertEqual(viewModel.viewState.selectionState.count, 4)
        XCTAssertTrue(viewModel.viewState.selectionState.values.allSatisfy { $0 })
    }
    
    func testUpdateRule() async {
        viewModel = .init(notificationSettingsService: notificationService, ruleIds: .default)
        notificationService.rules = [MockNotificationPushRule].default
        
        await viewModel.update(ruleID: .encrypted, isChecked: false)
        XCTAssertEqual(viewModel.viewState.selectionState.count, 4)
        XCTAssertEqual(viewModel.viewState.selectionState[.encrypted], false)
    }
    
    func testUpdateOneToOneRuleAlsoUpdatesPollRules() async {
        setupWithPollRules()
        
        await viewModel.update(ruleID: .oneToOneRoom, isChecked: false)

        XCTAssertEqual(viewModel.viewState.selectionState.count, 8)
        XCTAssertEqual(viewModel.viewState.selectionState[.oneToOneRoom], false)
        XCTAssertEqual(viewModel.viewState.selectionState[.oneToOnePollStart], false)
        XCTAssertEqual(viewModel.viewState.selectionState[.oneToOnePollEnd], false)
        
        // unrelated poll rules stay the same
        XCTAssertEqual(viewModel.viewState.selectionState[.allOtherMessages], true)
        XCTAssertEqual(viewModel.viewState.selectionState[.pollStart], true)
        XCTAssertEqual(viewModel.viewState.selectionState[.pollEnd], true)
    }
    
    func testUpdateMessageRuleAlsoUpdatesPollRules() async {
        setupWithPollRules()
        
        await viewModel.update(ruleID: .allOtherMessages, isChecked: false)
        XCTAssertEqual(viewModel.viewState.selectionState.count, 8)
        XCTAssertEqual(viewModel.viewState.selectionState[.allOtherMessages], false)
        XCTAssertEqual(viewModel.viewState.selectionState[.pollStart], false)
        XCTAssertEqual(viewModel.viewState.selectionState[.pollEnd], false)
        
        // unrelated poll rules stay the same
        XCTAssertEqual(viewModel.viewState.selectionState[.oneToOneRoom], true)
        XCTAssertEqual(viewModel.viewState.selectionState[.oneToOnePollStart], true)
        XCTAssertEqual(viewModel.viewState.selectionState[.oneToOnePollEnd], true)
    }
    
    func testMismatchingRulesAreHandled() async {
        setupWithPollRules()
        
        await viewModel.update(ruleID: .allOtherMessages, isChecked: false)
        
        // simulating a "mismatch" on the poll started rule
        await viewModel.update(ruleID: .pollStart, isChecked: true)
        
        XCTAssertEqual(viewModel.viewState.selectionState.count, 8)
        
        // The other messages rule ui flag should match the loudest related poll rule
        XCTAssertEqual(viewModel.viewState.selectionState[.allOtherMessages], true)
    }
    
    func testMismatchingOneToOneRulesAreHandled() async {
        setupWithPollRules()
        
        await viewModel.update(ruleID: .oneToOneRoom, isChecked: false)
        // simulating a "mismatch" on the one to one poll started rule
        await viewModel.update(ruleID: .oneToOnePollStart, isChecked: true)
        
        XCTAssertEqual(viewModel.viewState.selectionState.count, 8)
        
        // The one to one room rule ui flag should match the loudest related poll rule
        XCTAssertEqual(viewModel.viewState.selectionState[.oneToOneRoom], true)

        // the oneToOneRoom rule should be flagged as "out of sync"
        XCTAssertTrue(viewModel.isRuleOutOfSync(.oneToOneRoom))
        XCTAssertFalse(viewModel.isRuleOutOfSync(.allOtherMessages))
    }
}

private extension NotificationSettingsViewModelTests {
    func setupWithPollRules() {
        viewModel = .init(notificationSettingsService: notificationService, ruleIds: .default + .polls)
        notificationService.rules = [MockNotificationPushRule].default + [MockNotificationPushRule].polls
    }
}

private extension Array where Element == NotificationPushRuleId {
    static var `default`: [NotificationPushRuleId] {
        [.oneToOneRoom, .allOtherMessages, .oneToOneEncryptedRoom, .encrypted]
    }
    
    static var polls: [NotificationPushRuleId] {
        [.pollStart, .pollEnd, .oneToOnePollStart, .oneToOnePollEnd]
    }
}

private extension Array where Element == MockNotificationPushRule {
    static var `default`: [MockNotificationPushRule] {
        [NotificationPushRuleId]
            .default
            .map { ruleId in
                MockNotificationPushRule(ruleId: ruleId.rawValue, enabled: true)
            }
    }
    
    static var polls: [MockNotificationPushRule] {
        [NotificationPushRuleId]
            .polls
            .map { ruleId in
                MockNotificationPushRule(ruleId: ruleId.rawValue, enabled: true)
            }
    }
}
