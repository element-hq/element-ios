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

    init(notificationSettingsService: NotificationSettingsServiceType) {
        self.notificationSettingsService = notificationSettingsService
        
        notificationSettingsService
            .rulesPublisher
            .weakAssign(to: \.rules, on: self)
            .store(in: &cancellables)
    }
    
    func syncRulesIfNeeded() async {
        await withTaskGroup(of: Void.self) { [rules, notificationSettingsService] group in
            for rule in rules {
                guard let ruleId = rule.pushRuleId else {
                    continue
                }
                
                let relatedRules = ruleId.syncedRules(in: rules)
                
                for relatedRule in relatedRules {
                    guard rule.hasSameContentOf(relatedRule) == false else {
                        continue
                    }
                    
                    group.addTask {
                        try? await notificationSettingsService.updatePushRuleActions(for: relatedRule.ruleId,
                                                                                     enabled: rule.enabled,
                                                                                     actions: rule.ruleActions)
                    }
                }
            }
        }
    }
}

private extension NotificationPushRuleType {
    func hasSameContentOf(_ otherRule: NotificationPushRuleType) -> Bool? {
        enabled == otherRule.enabled && ruleActions == otherRule.ruleActions
    }
}
