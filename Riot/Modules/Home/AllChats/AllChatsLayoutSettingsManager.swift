// 
// Copyright 2022 New Vector Ltd
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

// MARK: - Notification constants

extension AllChatsLayoutSettingsManager {
    /// Posted if settings are about to change.
    public static let willUpdateSettings = Notification.Name("AllChatLayoutSettingsManagerWillUpdateSettings")
    /// Posted if settings have changed.
    public static let didUpdateSettings = Notification.Name("AllChatLayoutSettingsManagerDidUpdateSettings")
    
    /// Posted when active filters change
    public static let didUpdateActiveFilters = Notification.Name("AllChatLayoutSettingsManagerDidUpdateActiveFilters")
}

/// `AllChatsLayoutSettingsManager` single instance allows to read and write the settings data for the All Chat screen.
@objcMembers
final class AllChatsLayoutSettingsManager: NSObject {
    
    // MARK: - Singleton
    
    static let shared = AllChatsLayoutSettingsManager()
    
    // MARK: - Constants
    
    fileprivate enum Constants {
        static let settingsKey = "allChatLayoutSettings"
        static let activeFiltersKey = "allChatLayoutActiveFilters"
    }
    
    // MARK: - Setup
    
    private override init() {
        super.init()
    }

    // MARK: - Public
    
    var activeFilters: AllChatsLayoutFilterType {
        get {
            guard let value = RiotSettings.defaults.object(forKey: Constants.activeFiltersKey) as? NSNumber else {
                return .all
            }
            return AllChatsLayoutFilterType(rawValue: value.uintValue)
        }
        set {
            RiotSettings.defaults.set(newValue.rawValue, forKey: Constants.activeFiltersKey)
            
            track(activeFilters: newValue)
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: AllChatsLayoutSettingsManager.didUpdateActiveFilters, object: self)
            }
        }
    }
    
    var allChatLayoutSettings: AllChatsLayoutSettings {
        get {
            guard let data = RiotSettings.defaults.data(forKey: Constants.settingsKey) else {
                return AllChatsLayoutSettings()
            }
            
            do {
                return try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? AllChatsLayoutSettings ?? AllChatsLayoutSettings()
            } catch {
                return AllChatsLayoutSettings()
            }
        }
        set {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: AllChatsLayoutSettingsManager.willUpdateSettings, object: self)
            }
            
            if newValue.filters.isEmpty {
                track(activeFilters: nil)
            } else {
                track(activeFilters: activeFilters)
            }
            
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: false) else {
                MXLog.warning("[AllChatsLayoutSettingsManager] set allChatLayoutSettings: failed to archive settings")
                return
            }
            
            RiotSettings.defaults.set(data, forKey: Constants.settingsKey)
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: AllChatsLayoutSettingsManager.didUpdateSettings, object: self)
            }
        }
    }
    
    /// `true` if filters are activated in the All Chats Layout screen and a filter other than `.all` is active
    var hasAnActiveFilter: Bool {
        return !allChatLayoutSettings.filters.isEmpty && !activeFilters.isEmpty && activeFilters != .all
    }
    
    // MARK: - Private
    
    private func track(activeFilters: AllChatsLayoutFilterType?) {
        guard let activeFilters = activeFilters else {
            Analytics.shared.updateUserProperties(allChatsActiveFilter: nil)
            return
        }

        switch activeFilters {
        case [], .all:
            Analytics.shared.updateUserProperties(allChatsActiveFilter: .all)
        case .unreads:
            Analytics.shared.updateUserProperties(allChatsActiveFilter: .unreads)
        case .favourites:
            Analytics.shared.updateUserProperties(allChatsActiveFilter: .favourites)
        case .people:
            Analytics.shared.updateUserProperties(allChatsActiveFilter: .people)
        default:
            Analytics.shared.updateUserProperties(allChatsActiveFilter: nil)
        }
    }
}
