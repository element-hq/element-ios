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


fileprivate extension MXPushRule {
    
    /*
     Given a rule, check it match the actions in the static definition.
     */
    private func maches(targetRule: NotificationStandardActions?) -> Bool {
        guard let targetRule = targetRule else {
            return false
        }
        if !enabled && targetRule == .disabled {
            return true
        }
        
        if enabled,
           let actions = targetRule.actions,
           highlight == actions.highlight,
           sound == actions.sound,
           notify == actions.notify,
           dontNotify == !actions.notify {
            return true
        }
        return false
    }
    
    func getAction(actionType: MXPushRuleActionType, tweakType: String? = nil) -> MXPushRuleAction? {
        guard let actions = actions as? [MXPushRuleAction] else {
            return nil
        }
        
        return actions.first { action in
            var match = action.actionType == actionType
            MXLog.debug("action \(action)")
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
        return getAction(actionType: MXPushRuleActionTypeNotify) != nil
    }
    
    var dontNotify: Bool {
        return getAction(actionType: MXPushRuleActionTypeDontNotify) != nil
    }
}
