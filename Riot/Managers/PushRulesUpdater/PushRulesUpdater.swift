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
                self?.syncRulesIfNeeded()
            }
            .store(in: &cancellables)
    }
}

private extension PushRulesUpdater {
    func syncRulesIfNeeded() {
        print("*** check started: \(rules.count)")
        for rule in rules {
            syncRelatedRulesIfNeeded(for: rule)
        }
    }
    
    func syncRelatedRulesIfNeeded(for rule: NotificationPushRuleType) {
        guard let ruleId = rule.pushRuleId else {
            return
        }
        
        let relatedRules = ruleId.syncedRules(in: rules)
        
        for relatedRule in relatedRules {
            guard rule.hasSameContentOf(relatedRule) == false else {
                print("*** OK -> rule: \(relatedRule.ruleId)")
                continue
            }
            
            print("*** mismatch -> rule: \(relatedRule.ruleId)")
            sync(relatedRuleId: relatedRule.ruleId, with: rule)
        }
    }
    
    func sync(relatedRuleId: String, with rule: NotificationPushRuleType) {
        let notificationOption = NotificationIndex.index(when: rule.enabled)
        
        guard
            let ruleId = rule.pushRuleId,
            let expectedActions = ruleId.standardActions(for: notificationOption).actions
        else {
            return
        }
        
        Task {
            try? await notificationSettingsService.updatePushRuleActions(for: relatedRuleId, enabled: rule.enabled, actions: expectedActions)
        }
    }
}

private extension NotificationPushRuleType {
    func hasSameContentOf(_ otherRule: NotificationPushRuleType) -> Bool {
        guard let ruleId = pushRuleId else {
            return false
        }
        
        let notificationOption = NotificationIndex.index(when: enabled)
        return otherRule.matches(standardActions: ruleId.standardActions(for: notificationOption))
    }
}
