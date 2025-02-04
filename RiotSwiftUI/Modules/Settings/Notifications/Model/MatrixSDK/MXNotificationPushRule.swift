//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import DesignKit
import Foundation

// Conformance of MXPushRule to the abstraction `NotificationPushRule` for use in `NotificationSettingsViewModel`.
extension MXPushRule: NotificationPushRuleType {
    /// Given a rule, check it match the actions in the static definition.
    /// - Parameter standardActions: The standard actions to match against.
    /// - Returns: Wether `this` rule matches the standard actions.
    func matches(standardActions: NotificationStandardActions?) -> Bool {
        guard let standardActions = standardActions else {
            return false
        }
        if !enabled, standardActions == .disabled {
            return true
        }
        
        if enabled,
           let actions = standardActions.actions,
           highlight == actions.highlight,
           sound == actions.sound,
           notify == actions.notify,
           dontNotify == !actions.notify {
            return true
        }
        return false
    }
    
    var ruleActions: NotificationActions? {
        .init(notify: notify, highlight: highlight, sound: sound)
    }
    
    private func getAction(actionType: MXPushRuleActionType, tweakType: String? = nil) -> MXPushRuleAction? {
        guard let actions = actions as? [MXPushRuleAction] else {
            return nil
        }
        
        return actions.first { action in
            var match = action.actionType == actionType
            if let tweakType = tweakType,
               let actionTweak = action.parameters?["set_tweak"] as? String {
                match = match && (tweakType == actionTweak)
            }
            return match
        }
    }
    
    var highlight: Bool {
        guard let action = getAction(actionType: MXPushRuleActionTypeSetTweak, tweakType: "highlight") else {
            return false
        }
        if let highlight = action.parameters["value"] as? Bool {
            return highlight
        }
        return true
    }
    
    var sound: String? {
        guard let action = getAction(actionType: MXPushRuleActionTypeSetTweak, tweakType: "sound") else {
            return nil
        }
        return action.parameters["value"] as? String
    }
    
    var notify: Bool {
        getAction(actionType: MXPushRuleActionTypeNotify) != nil
    }
    
    var dontNotify: Bool {
        guard let actions = actions as? [MXPushRuleAction] else {
            return true
        }
        // Support for MSC3987: The dont_notify push rule action is deprecated and replaced by an empty actions list.
        return actions.isEmpty || getAction(actionType: MXPushRuleActionTypeDontNotify) != nil
    }
}
