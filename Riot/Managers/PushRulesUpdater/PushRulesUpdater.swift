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

final class PushRulesUpdater {
    private var cancellables: Set<AnyCancellable> = .init()
    private var rules: [NotificationPushRuleType] = []
    private let notificationSettingsService: NotificationSettingsServiceType
    
    init(notificationSettingsService: NotificationSettingsServiceType, needsCheck: AnyPublisher<Void, Never>) {
        self.notificationSettingsService = notificationSettingsService
        
        notificationSettingsService
            .rulesPublisher
            .weakAssign(to: \.rules, on: self)
            .store(in: &cancellables)
        
        needsCheck
            .sink { [weak self] _ in
                self?.updateRulesIfNeeded()
            }
            .store(in: &cancellables)
    }
}

private extension PushRulesUpdater {
    func updateRulesIfNeeded() {
        print("*** check started: \(rules.count)")
        for rule in rules {
            syncRelatedRulesIfNeeded(for: rule)
        }
    }
    
    func syncRelatedRulesIfNeeded(for rule: NotificationPushRuleType) {
        guard let ruleId = NotificationPushRuleId(rawValue: rule.ruleId) else {
            return
        }
        
        let relatedRules = ruleId.syncedRules(in: rules)
        
        for relatedRule in relatedRules {
            guard rule.hasSameContent(relatedRule) == false else {
                print("*** OK -> rule: \(relatedRule.ruleId)")
                continue
            }
            
            let notificationOption = NotificationIndex.index(when: rule.enabled)
            
            guard
                let ruleId = NotificationPushRuleId(rawValue: rule.ruleId),
                let expectedActions = ruleId.standardActions(for: notificationOption).actions
            else {
                return
            }
            
            print("*** mismatch -> rule: \(relatedRule.ruleId)")
            Task {
                try? await notificationSettingsService.updatePushRuleActions(for: relatedRule.ruleId, enabled: rule.enabled, actions: expectedActions)
            }
        }
    }
}

extension NotificationPushRuleType {
    func hasSameContent(_ otherRule: NotificationPushRuleType) -> Bool {
        guard let ruleId = NotificationPushRuleId(rawValue: ruleId) else {
            return false
        }
        
        let notificationOption = NotificationIndex.index(when: enabled)
        return otherRule.matches(standardActions: ruleId.standardActions(for: notificationOption))
    }
}

private extension MXPushRule {
    var mxActions: [MXPushRuleAction]? {
        actions as? [MXPushRuleAction]
    }
}
