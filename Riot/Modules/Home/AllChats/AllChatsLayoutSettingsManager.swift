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
}

@objcMembers
final class AllChatsLayoutSettingsManager: NSObject {
    
    static let shared = AllChatsLayoutSettingsManager()
    private var notifyChanges: Bool = true
    
    /// UserDefaults to be used on reads and writes.
    static var defaults: UserDefaults = {
        guard let userDefaults = UserDefaults(suiteName: BuildSettings.applicationGroupIdentifier) else {
            fatalError("[AllChatLayoutSettingsManager] Fail to load shared UserDefaults")
        }
        return userDefaults
    }()
    
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(forName: AllChatsLayoutSettings.didUpdateFilters, object: nil, queue: OperationQueue.main) { [weak self] notification in
            guard let self = self, let settings = notification.object as? AllChatsLayoutSettings else {
                return
            }
            
            self.notifyChanges = false
            self.allChatLayoutSettings = settings
        }
    }

    var allChatLayoutSettings: AllChatsLayoutSettings {
        get {
            guard let data = Self.defaults.object(forKey: "allChatLayoutSettings") as? Data else {
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
                if self.notifyChanges {
                    NotificationCenter.default.post(name: AllChatsLayoutSettingsManager.willUpdateSettings, object: self)
                }
            }
            let data = NSKeyedArchiver.archivedData(withRootObject: newValue)
            Self.defaults.set(data, forKey: "allChatLayoutSettings")
            Self.defaults.synchronize()
            
            DispatchQueue.main.async {
                if self.notifyChanges {
                    NotificationCenter.default.post(name: AllChatsLayoutSettingsManager.didUpdateSettings, object: self)
                }
                self.notifyChanges = true
            }
        }
    }
}
