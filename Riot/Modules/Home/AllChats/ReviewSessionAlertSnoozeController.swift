// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objcMembers
class ReviewSessionAlertSnoozeController: NSObject {
    
    private let userDefaults: UserDefaults
    private let snoozeDateKey = "ReviewSessionAlertSnoozeController_snoozeDateKey"
    private let minDaysBetweenAlerts = 7
    
    // for Objective-C
    convenience override init() {
        self.init(userDefaults: UserDefaults.standard)
    }
    
    init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }
    
    func isSnoozed() -> Bool {
        guard  let lastDisplayedDate = userDefaults.object(forKey: snoozeDateKey) as? Date else {
            return false
        }
        return lastDisplayedDate.daysBetween(date: Date()) <= minDaysBetweenAlerts
    }
    
    func snooze() {
        userDefaults.set(Date(), forKey: snoozeDateKey)
    }
    
    func clearSnooze() {
        userDefaults.removeObject(forKey: snoozeDateKey)
    }
}
