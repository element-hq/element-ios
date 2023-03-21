//
// Copyright 2021 New Vector Ltd
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
import Foundation

class MXNotificationSettingsService: NotificationSettingsServiceType {
    private let session: MXSession
    private var cancellables = Set<AnyCancellable>()
    
    @Published private var contentRules = [MXPushRule]()
    @Published private var rules = [MXPushRule]()
    
    var rulesPublisher: AnyPublisher<[NotificationPushRuleType], Never> {
        $rules.map { $0.map { $0 as NotificationPushRuleType } }.eraseToAnyPublisher()
    }
    
    var contentRulesPublisher: AnyPublisher<[NotificationPushRuleType], Never> {
        $contentRules.map { $0.map { $0 as NotificationPushRuleType } }.eraseToAnyPublisher()
    }
    
    init(session: MXSession) {
        self.session = session
        // Publisher of all rule updates
        let rulesUpdated = NotificationCenter.default.publisher(for: NSNotification.Name(rawValue: kMXNotificationCenterDidUpdateRules))
        
        // Set initial value of the content rules
        if let contentRules = session.notificationCenter.rules?.global.content as? [MXPushRule] {
            self.contentRules = contentRules
        }
        
        // Observe future updates to content rules
        rulesUpdated
            .compactMap { [weak self] _ in
                self?.session.notificationCenter.rules.global.content as? [MXPushRule]
            }
            .assign(to: &$contentRules)
        
        // Set initial value of rules
        if let flatRules = session.notificationCenter.flatRules as? [MXPushRule] {
            rules = flatRules
        }
        // Observe future updates to rules
        rulesUpdated
            .compactMap { [weak self] _ in
                self?.session.notificationCenter.flatRules as? [MXPushRule]
            }
            .assign(to: &$rules)
    }
    
    func add(keyword: String, enabled: Bool) {
        let index = NotificationIndex.index(when: enabled)
        guard let actions = NotificationPushRuleId.keywords.standardActions(for: index).actions else {
            return
        }
        session.notificationCenter.addContentRuleWithRuleId(matchingPattern: keyword, notify: actions.notify, sound: actions.sound, highlight: actions.highlight)
    }
    
    func remove(keyword: String) {
        guard let rule = session.notificationCenter.rule(byId: keyword) else { return }
        session.notificationCenter.removeRule(rule)
    }
    
    func updatePushRuleActions(for ruleId: String,
                               enabled: Bool,
                               actions: NotificationActions?) async throws {
        
        guard let rule = session.notificationCenter.rule(byId: ruleId) else {
            return
        }
        
        guard let actions = actions else {
            try await session.notificationCenter.enableRule(pushRule: rule, isEnabled: enabled)
            return
        }
        
        // Updating the actions before enabling the rule allows the homeserver to triggers just one sync update
        try await session.notificationCenter.updatePushRuleActions(ruleId,
                                                                   kind: rule.kind,
                                                                   notify: actions.notify,
                                                                   soundName: actions.sound,
                                                                   highlight: actions.highlight)
        
        try await session.notificationCenter.enableRule(pushRule: rule, isEnabled: enabled)
    }
}

private extension MXNotificationCenter {
    func enableRule(pushRule: MXPushRule, isEnabled: Bool) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            enableRule(pushRule, isEnabled: isEnabled) { error in
                if let error = error {
                    continuation.resume(with: .failure(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func updatePushRuleActions(ruleId: String, kind: __MXPushRuleKind, notify: Bool, soundName: String, highlight: Bool) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            updatePushRuleActions(ruleId, kind: kind, notify: notify, soundName: soundName, highlight: highlight) { error in
                if let error = error {
                    continuation.resume(with: .failure(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
