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

import Foundation
import Combine

/// A service for changing notification settings and keywords
protocol NotificationSettingsServiceType {
    /// Publisher of all push rules.
    var rulesPublisher: AnyPublisher<[NotificationPushRuleType], Never> { get }
    
    /// Publisher of content rules.
    var contentRulesPublisher: AnyPublisher<[NotificationPushRuleType], Never> { get }
    
    /// Adds a keyword.
    /// - Parameters:
    ///   - keyword: The keyword to add.
    ///   - enabled: Whether the keyword should be added in the enabled or disabled state.
    func add(keyword: String, enabled: Bool)
    
    /// Removes a keyword.
    /// - Parameter keyword: The keyword to remove.
    func remove(keyword: String)
    
    /// Updates the push rule actions.
    /// - Parameters:
    ///   - ruleId: The id of the rule.
    ///   - enabled: Whether the rule should be enabled or disabled.
    ///   - actions: The actions to update with.
    func updatePushRuleActions(for ruleId: String, enabled: Bool, actions: NotificationActions?)
}
