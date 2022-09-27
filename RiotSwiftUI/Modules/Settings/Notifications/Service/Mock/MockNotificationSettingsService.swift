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

class MockNotificationSettingsService: NotificationSettingsServiceType, ObservableObject {
    static let example = MockNotificationSettingsService()
    
    @Published var keywords = Set<String>()
    @Published var rules = [NotificationPushRuleType]()
    @Published var contentRules = [NotificationPushRuleType]()
    
    var contentRulesPublisher: AnyPublisher<[NotificationPushRuleType], Never> {
        $contentRules.eraseToAnyPublisher()
    }
    
    var keywordsPublisher: AnyPublisher<Set<String>, Never> {
        $keywords.eraseToAnyPublisher()
    }
    
    var rulesPublisher: AnyPublisher<[NotificationPushRuleType], Never> {
        $rules.eraseToAnyPublisher()
    }
    
    func add(keyword: String, enabled: Bool) {
        keywords.insert(keyword)
    }
    
    func remove(keyword: String) {
        keywords.remove(keyword)
    }
    
    func updatePushRuleActions(for ruleId: String, enabled: Bool, actions: NotificationActions?) { }
}
