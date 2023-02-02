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
    private var rules: [MXPushRule] = []
    
    init(checkSignal: AnyPublisher<Void, Never>, rulesProvider: AnyPublisher<[MXPushRule], Never>) {
        rulesProvider
            .weakAssign(to: \.rules, on: self)
            .store(in: &cancellables)
        
        checkSignal
            .sink { [weak self] _ in
                self?.updateRulesIfNeeded()
            }
            .store(in: &cancellables)
    }
}

private extension PushRulesUpdater {
    func updateRulesIfNeeded() {
        for rule in rules {
            syncRelatedRulesIfNeeded(for: rule)
        }
    }
    
    func syncRelatedRulesIfNeeded(for rule: MXPushRule) {
        let relatedRules = rule.syncedRules(in: rules)
        
        for relatedRule in relatedRules {
            guard MXPushRule.haveSameContent(relatedRule, rule) == false else {
                MXLog.debug("*** mismatch -> rule: \(relatedRule.ruleId)")
                continue
            }
            
            MXLog.debug("*** OK -> rule: \(relatedRule.ruleId)")
        }
    }
}

private extension MXPushRule {
    func syncedRules(in rules: [MXPushRule]) -> [MXPushRule] {
        guard let ruleId = NotificationPushRuleId(rawValue: ruleId) else {
            return []
        }
        
        return rules.filter {
            guard let someRuleId = NotificationPushRuleId(rawValue: $0.ruleId) else {
                return false
            }
            return ruleId.syncedRules.contains(someRuleId)
        }
    }
    
    static func haveSameContent(_ firstRule: MXPushRule, _ secondRule: MXPushRule) -> Bool {
        guard
            firstRule.enabled == secondRule.enabled,
            let firstActions = firstRule.mxActions,
            let secondActions = secondRule.mxActions,
            firstActions.count == secondActions.count
        else {
            return false
        }
        
        return firstActions.indices.allSatisfy { index in
            let action1 = firstActions[index]
            let action2 = secondActions[index]
            #warning("compare  @property (nonatomic) NSDictionary *parameters")
            return action1.actionType == action2.actionType
        }
    }
}

private extension MXPushRule {
    var mxActions: [MXPushRuleAction]? {
        actions as? [MXPushRuleAction]
    }
}
