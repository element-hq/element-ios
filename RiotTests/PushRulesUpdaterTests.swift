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

import Combine
import XCTest
@testable import Element

final class PushRulesUpdaterTests: XCTestCase {
    private var notificationService: MockNotificationSettingsService!
    private var pushRulesUpdater: PushRulesUpdater!

    override func setUpWithError() throws {
        notificationService = .init()
        notificationService.rules = [MockNotificationPushRule].default
        pushRulesUpdater = .init(notificationSettingsService: notificationService)
    }

    func testNoRuleIsUpdated() async throws {
        await pushRulesUpdater.syncRulesIfNeeded()
        XCTAssertEqual(notificationService.rules as? [MockNotificationPushRule], [MockNotificationPushRule].default)
    }
    
    func testSingleRuleAffected() async throws {
        let targetActions: NotificationActions = .init(notify: true, sound: "default")
        let targetRuleIndex = try mockRule(ruleId: .pollStart, enabled: false, actions: targetActions)
        
        await pushRulesUpdater.syncRulesIfNeeded()

        XCTAssertEqual(self.notificationService.rules[targetRuleIndex].ruleActions, NotificationStandardActions.notifyDefaultSound.actions)
        XCTAssertTrue(self.notificationService.rules[targetRuleIndex].enabled)
    }
    
    func testAffectedRulesAreUpdated() async throws {
        let targetActions: NotificationActions = .init(notify: true, sound: "abc")
        try mockRule(ruleId: .allOtherMessages, enabled: true, actions: targetActions)
        let affectedRules: [NotificationPushRuleId] =  [.allOtherMessages, .pollStart, .msc3930pollStart, .pollEnd, .msc3930pollEnd]
        
        await pushRulesUpdater.syncRulesIfNeeded()
        
        for rule in self.notificationService.rules {
            guard let id = rule.pushRuleId else {
                continue
            }
            
            if affectedRules.contains(id) {
                XCTAssertEqual(rule.ruleActions, targetActions)
            } else {
                XCTAssertEqual(rule.ruleActions, NotificationStandardActions.notifyDefaultSound.actions)
            }
        }
    }
    
    func testAffectedOneToOneRulesAreUpdated() async throws {
        let targetActions: NotificationActions = .init(notify: true, sound: "abc")
        try mockRule(ruleId: .oneToOneRoom, enabled: true, actions: targetActions)
        let affectedRules: [NotificationPushRuleId] =  [.oneToOneRoom, .oneToOnePollStart, .msc3930oneToOnePollStart, .oneToOnePollEnd, .msc3930oneToOnePollEnd]
        
        await pushRulesUpdater.syncRulesIfNeeded()
        
        for rule in self.notificationService.rules {
            guard let id = rule.pushRuleId else {
                continue
            }
            
            if affectedRules.contains(id) {
                XCTAssertEqual(rule.ruleActions, targetActions)
            } else {
                XCTAssertEqual(rule.ruleActions, NotificationStandardActions.notifyDefaultSound.actions)
            }
        }
    }
}

private extension PushRulesUpdaterTests {
    @discardableResult
    func mockRule(ruleId: NotificationPushRuleId, enabled: Bool, actions: NotificationActions) throws -> Int {
        guard let ruleIndex = notificationService.rules.firstIndex(where: { $0.pushRuleId == ruleId }) else {
            throw NSError(domain: "no ruleIndex found", code: 0)
        }
        notificationService.rules[ruleIndex] = MockNotificationPushRule(ruleId: ruleId.rawValue, enabled: enabled, ruleActions: actions)
        return ruleIndex
    }
}

private extension Array where Element == MockNotificationPushRule {
    static var `default`: [MockNotificationPushRule] {
        let ids: [NotificationPushRuleId] =  [.oneToOneRoom, .allOtherMessages, .pollStart, .msc3930pollStart, .pollEnd, .msc3930pollEnd, .oneToOnePollStart, .msc3930oneToOnePollStart, .oneToOnePollEnd, .msc3930oneToOnePollEnd]
        
        return ids.map {
            MockNotificationPushRule(ruleId: $0.rawValue, enabled: true)
        }
    }
}
