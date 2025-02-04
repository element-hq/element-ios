//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

final class MXRoomNotificationSettingsService: RoomNotificationSettingsServiceType {
    typealias Completion = () -> Void
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let room: MXRoom
    
    private var notificationCenterDidUpdateObserver: NSObjectProtocol?
    private var notificationCenterDidFailObserver: NSObjectProtocol?
    
    private var observers: [ObjectIdentifier] = []
    
    private var notificationCenter: MXNotificationCenter? {
        room.mxSession?.notificationCenter
    }
    
    // MARK: Public
    
    var notificationState: RoomNotificationState {
        room.notificationState
    }

    // MARK: - Setup
    
    init(room: MXRoom) {
        self.room = room
    }
    
    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }
    
    // MARK: - Public
    
    func observeNotificationState(listener: @escaping RoomNotificationStateCallback) {
        let observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: kMXNotificationCenterDidUpdateRules),
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] _ in
            guard let self = self else { return }
            listener(self.room.notificationState)
        }
        observers += [ObjectIdentifier(observer)]
    }
    
    func update(state: RoomNotificationState, completion: @escaping Completion) {
        switch state {
        case .all:
            allMessages(completion: completion)
        case .mentionsAndKeywordsOnly:
            mentionsOnly(completion: completion)
        case .mute:
            mute(completion: completion)
        }
    }
    
    // MARK: - Private
    
    private func mute(completion: @escaping Completion) {
        guard !room.isMuted else {
            completion()
            return
        }
        
        if let rule = room.roomPushRule {
            removePushRule(rule: rule) {
                self.mute(completion: completion)
            }
            return
        }
        
        guard let rule = room.overridePushRule else {
            addPushRuleToMute(completion: completion)
            return
        }
        
        guard notificationCenterDidUpdateObserver == nil else {
            MXLog.debug("[RoomNotificationSettingsService] Request in progress: ignore push rule update")
            completion()
            return
        }
        
        // if the user defined one, use it
        if rule.dontNotify {
            enablePushRule(rule: rule, completion: completion)
        } else {
            removePushRule(rule: rule) {
                self.addPushRuleToMute(completion: completion)
            }
        }
    }
    
    private func mentionsOnly(completion: @escaping Completion) {
        guard !room.isMentionsOnly else {
            completion()
            return
        }
        
        if let rule = room.overridePushRule, room.isMuted {
            removePushRule(rule: rule) {
                self.mentionsOnly(completion: completion)
            }
            return
        }
        
        guard let rule = room.roomPushRule else {
            addPushRuleToMentionOnly(completion: completion)
            return
        }
        
        guard notificationCenterDidUpdateObserver == nil else {
            MXLog.debug("[MXRoom+Riot] Request in progress: ignore push rule update")
            completion()
            return
        }
        
        // if the user defined one, use it
        if rule.dontNotify {
            enablePushRule(rule: rule, completion: completion)
        } else {
            removePushRule(rule: rule) {
                self.addPushRuleToMentionOnly(completion: completion)
            }
        }
    }
    
    private func allMessages(completion: @escaping Completion) {
        if !room.isMentionsOnly, !room.isMuted {
            completion()
            return
        }
        
        if let rule = room.overridePushRule, room.isMuted {
            removePushRule(rule: rule) {
                self.allMessages(completion: completion)
            }
            return
        }
        
        if let rule = room.roomPushRule, room.isMentionsOnly {
            removePushRule(rule: rule, completion: completion)
        }
    }
    
    private func addPushRuleToMentionOnly(completion: @escaping Completion) {
        handleUpdateCallback(completion) { [weak self] in
            guard let self = self else { return true }
            return self.room.roomPushRule != nil
        }
        handleFailureCallback(completion)
        
        notificationCenter?.addRoomRule(
            room.roomId,
            notify: false,
            sound: false,
            highlight: false
        )
    }
    
    private func addPushRuleToMute(completion: @escaping Completion) {
        guard let roomId = room.roomId else {
            return
        }
        handleUpdateCallback(completion) { [weak self] in
            guard let self = self else { return true }
            return self.room.overridePushRule != nil
        }
        handleFailureCallback(completion)
        
        notificationCenter?.addOverrideRule(
            withId: roomId,
            conditions: [["kind": "event_match", "key": "room_id", "pattern": roomId]],
            notify: false,
            sound: false,
            highlight: false
        )
    }
    
    private func removePushRule(rule: MXPushRule, completion: @escaping Completion) {
        handleUpdateCallback(completion) { [weak self] in
            guard let self = self else { return true }
            return self.notificationCenter?.rule(byId: rule.ruleId) == nil
        }
        handleFailureCallback(completion)
        
        notificationCenter?.removeRule(rule)
    }
    
    private func enablePushRule(rule: MXPushRule, completion: @escaping Completion) {
        handleUpdateCallback(completion) {
            // No way to check whether this notification concerns the push rule. Consider the change is applied.
            true
        }
        handleFailureCallback(completion)
        
        notificationCenter?.enableRule(rule, isEnabled: true)
    }
    
    private func handleUpdateCallback(_ completion: @escaping Completion, releaseCheck: @escaping () -> Bool) {
        notificationCenterDidUpdateObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: kMXNotificationCenterDidUpdateRules),
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] _ in
            guard let self = self else { return }
            if releaseCheck() {
                self.removeObservers()
                completion()
            }
        }
    }
    
    private func handleFailureCallback(_ completion: @escaping Completion) {
        notificationCenterDidFailObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: kMXNotificationCenterDidFailRulesUpdate),
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.removeObservers()
            completion()
        }
    }
    
    func removeObservers() {
        if let observer = notificationCenterDidUpdateObserver {
            NotificationCenter.default.removeObserver(observer)
            notificationCenterDidUpdateObserver = nil
        }
        
        if let observer = notificationCenterDidFailObserver {
            NotificationCenter.default.removeObserver(observer)
            notificationCenterDidFailObserver = nil
        }
    }
}

public extension MXRoom {
    var isMuted: Bool {
        // Check whether an override rule has been defined with the roomm id as rule id.
        // This kind of rule is created to mute the room
        guard let rule = overridePushRule,
              rule.dontNotify,
              rule.conditionIsEnabled(kind: .eventMatch, for: roomId) else {
            return false
        }
        return rule.enabled
    }
    
    var isMentionsOnly: Bool {
        // Check push rules at room level
        guard let rule = roomPushRule else { return false }
        return rule.enabled && rule.dontNotify
    }
}

// We could move these to their own file and make available in global namespace or move to sdk but they are only used here at the moment
private extension MXRoom {
    typealias Completion = () -> Void
    func getRoomRule(from rules: [Any]) -> MXPushRule? {
        guard let pushRules = rules as? [MXPushRule] else {
            return nil
        }
        
        return pushRules.first(where: { self.roomId == $0.ruleId })
    }
    
    var overridePushRule: MXPushRule? {
        guard let overrideRules = mxSession?.notificationCenter?.rules?.global?.override else {
            return nil
        }
        return getRoomRule(from: overrideRules)
    }
    
    var roomPushRule: MXPushRule? {
        guard let roomRules = mxSession?.notificationCenter?.rules?.global?.room else {
            return nil
        }
        return getRoomRule(from: roomRules)
    }
    
    var notificationState: RoomNotificationState {
        if isMuted {
            return .mute
        }
        if isMentionsOnly {
            return .mentionsAndKeywordsOnly
        }
        return .all
    }
}

private extension MXPushRule {
    func actionsContains(actionType: MXPushRuleActionType) -> Bool {
        guard let actions = actions as? [MXPushRuleAction] else {
            return false
        }
        return actions.contains(where: { $0.actionType == actionType })
    }
    
    func conditionIsEnabled(kind: MXPushRuleConditionType, for roomId: String) -> Bool {
        guard let conditions = conditions as? [MXPushRuleCondition] else {
            return false
        }
        let ruleContainsCondition = conditions.contains { condition in
            guard case kind = MXPushRuleConditionType(identifier: condition.kind),
                  let key = condition.parameters["key"] as? String,
                  let pattern = condition.parameters["pattern"] as? String
            else { return false }
            return key == "room_id" && pattern == roomId
        }
        return ruleContainsCondition && enabled
    }
}
