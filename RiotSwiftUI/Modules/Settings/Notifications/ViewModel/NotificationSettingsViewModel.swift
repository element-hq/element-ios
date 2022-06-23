// File created from ScreenTemplate
// $ createScreen.sh Settings/Notifications NotificationSettings
/*
 Copyright 2021 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import Combine
import SwiftUI

final class NotificationSettingsViewModel: NotificationSettingsViewModelType, ObservableObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let notificationSettingsService: NotificationSettingsServiceType
    // The rule ids this view model allows the ui to enabled/disable.
    private let ruleIds: [NotificationPushRuleId]
    private var cancellables = Set<AnyCancellable>()
    
    // The ordered array of keywords the UI displays.
    // We keep it ordered so keywords don't jump around when being added and removed.
    @Published private var keywordsOrdered = [String]()
    
    // MARK: Public
    
    @Published var viewState: NotificationSettingsViewState
    
    weak var coordinatorDelegate: NotificationSettingsViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(notificationSettingsService: NotificationSettingsServiceType, ruleIds: [NotificationPushRuleId], initialState: NotificationSettingsViewState) {
        self.notificationSettingsService = notificationSettingsService
        self.ruleIds = ruleIds
        self.viewState = initialState
        
        // Observe when the rules are updated, to subsequently update the state of the settings.
        notificationSettingsService.rulesPublisher
            .sink(receiveValue: rulesUpdated(newRules:))
            .store(in: &cancellables)
        
        // Only observe keywords if the current settings view displays it.
        if ruleIds.contains(.keywords) {
            // Publisher of all the keyword push rules (keyword rules do not start with '.')
            let keywordsRules = notificationSettingsService.contentRulesPublisher
                .map { $0.filter { !$0.ruleId.starts(with: ".")} }
            
            // Map to just the keyword strings
            let keywords = keywordsRules
                .map { Set($0.compactMap { $0.ruleId }) }
            
            // Update the keyword set
            keywords
                .sink { [weak self] updatedKeywords in
                    guard let self = self else { return }
                    // We avoid simply assigning the new set as it would cause all keywords to get sorted lexigraphically.
                    // We first sort lexigraphically, and secondly preserve the order the user added them.
                    // The following adds/removes any updates while preserving that ordering.
                    
                    // Remove keywords not in the updated set.
                    var newKeywordsOrdered = self.keywordsOrdered.filter { keyword in
                        updatedKeywords.contains(keyword)
                    }
                    // Append items in the updated set if they are not already added.
                    // O(n)² here. Will change keywordsOrdered back to an `OrderedSet` in future to fix this.
                    updatedKeywords.sorted().forEach { keyword in
                        if !newKeywordsOrdered.contains(keyword) {
                            newKeywordsOrdered.append(keyword)
                        }
                    }
                    self.keywordsOrdered = newKeywordsOrdered
                }
                .store(in: &cancellables)
            
            // Keyword rules were updates, check if we need to update the setting.
            keywordsRules
                .map { $0.contains { $0.enabled } }
                .sink(receiveValue: keywordRuleUpdated(anyEnabled:))
                .store(in: &cancellables)
            
            // Update the viewState with the final keywords to be displayed.
            $keywordsOrdered
                .weakAssign(to: \.viewState.keywords, on: self)
                .store(in: &cancellables)
        }
    }
    
    convenience init(notificationSettingsService: NotificationSettingsServiceType, ruleIds: [NotificationPushRuleId]) {
        let ruleState = Dictionary(uniqueKeysWithValues: ruleIds.map({ ($0, selected: true) }))
        self.init(notificationSettingsService: notificationSettingsService, ruleIds: ruleIds, initialState: NotificationSettingsViewState(saving: false, ruleIds: ruleIds, selectionState: ruleState))
    }
    
    // MARK: - Public
    
    func update(ruleID: NotificationPushRuleId, isChecked: Bool) {
        let index = NotificationIndex.index(when: isChecked)
        if ruleID == .keywords {
            // Keywords is handled differently to other settings
            updateKeywords(isChecked: isChecked)
            return
        }
        // Get the static definition and update the actions and enabled state.
        guard let standardActions = ruleID.standardActions(for: index) else { return }
        let enabled = standardActions != .disabled
        notificationSettingsService.updatePushRuleActions(
            for: ruleID.rawValue,
            enabled: enabled,
            actions: standardActions.actions
        )
    }
    
    private func updateKeywords(isChecked: Bool) {
        guard !keywordsOrdered.isEmpty else {
            self.viewState.selectionState[.keywords]?.toggle()
            return
        }
        // Get the static definition and update the actions and enabled state for every keyword.
        let index = NotificationIndex.index(when: isChecked)
        guard let standardActions = NotificationPushRuleId.keywords.standardActions(for: index) else { return }
        let enabled = standardActions != .disabled
        keywordsOrdered.forEach { keyword in
            notificationSettingsService.updatePushRuleActions(
                for: keyword,
                enabled: enabled,
                actions: standardActions.actions
            )
        }
    }
    
    func add(keyword: String) {
        if !keywordsOrdered.contains(keyword) {
            keywordsOrdered.append(keyword)
        }
        notificationSettingsService.add(keyword: keyword, enabled: true)
    }
    
    func remove(keyword: String) {
        keywordsOrdered = keywordsOrdered.filter({ $0 != keyword })
        notificationSettingsService.remove(keyword: keyword)
    }
    
    // MARK: - Private
    private func rulesUpdated(newRules: [NotificationPushRuleType]) {
        for rule in newRules {
            guard let ruleId = NotificationPushRuleId(rawValue: rule.ruleId),
                  ruleIds.contains(ruleId) else { continue }
            self.viewState.selectionState[ruleId] = self.isChecked(rule: rule)
        }
    }
    
    private func keywordRuleUpdated(anyEnabled: Bool) {
        if !keywordsOrdered.isEmpty {
            self.viewState.selectionState[.keywords] = anyEnabled
        }
    }
      
    /// Given a push rule check which index/checked state it matches.
    ///
    /// Matching is done by comparing the rule against the static definitions for that rule.
    /// The same logic is used on android.
    /// - Parameter rule: The push rule type to check.
    /// - Returns: Wether it should be displayed as checked or not checked.
    private func isChecked(rule: NotificationPushRuleType) -> Bool {
        guard let ruleId = NotificationPushRuleId(rawValue: rule.ruleId) else { return false }
        
        let firstIndex = NotificationIndex.allCases.first { nextIndex in
            return rule.matches(standardActions: ruleId.standardActions(for: nextIndex))
        }
        
        guard let index = firstIndex else {
            return false
        }
        
        return index.enabled
    }

}
