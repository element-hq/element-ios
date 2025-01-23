//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

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
    func updatePushRuleActions(for ruleId: String, enabled: Bool, actions: NotificationActions?) async throws
}
