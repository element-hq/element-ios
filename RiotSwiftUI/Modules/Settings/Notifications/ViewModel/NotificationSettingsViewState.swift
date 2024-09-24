// File created from ScreenTemplate
// $ createScreen.sh Settings/Notifications NotificationSettings
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

struct NotificationSettingsViewState {
    var saving: Bool
    var ruleIds: [NotificationPushRuleId]
    var selectionState: [NotificationPushRuleId: Bool]
    var outOfSyncRules: Set<NotificationPushRuleId> = .init()
    var keywords = [String]()
}
