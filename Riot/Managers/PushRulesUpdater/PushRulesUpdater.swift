// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
