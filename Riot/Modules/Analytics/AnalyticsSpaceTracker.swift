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

class AnalyticsSpaceTracker {
    // MARK: - Constants

    private enum Constants {
        static let lastNumberOfSpaces: String = "AnalyticsSpaceTracker.lastNumberOfSpaces"
    }
    
    // Last number of spaces tracked
    private var lastNumberOfSpaces: Int? {
        get {
            guard let value = UserDefaults.standard.value(forKey: Constants.lastNumberOfSpaces) as? NSNumber else {
                return nil
            }
            
            return value.intValue
        }
        
        set {
            guard let value = newValue else {
                UserDefaults.standard.removeObject(forKey: Constants.lastNumberOfSpaces)
                return
            }
            
            UserDefaults.standard.setValue(NSNumber(value: value), forKey: Constants.lastNumberOfSpaces)
        }
    }

    // MARK: - Setup
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.spaceGraphDidUpdate(notification:)), name: MXSpaceService.didBuildSpaceGraph, object: nil)
    }
    
    @objc private func spaceGraphDidUpdate(notification: Notification) {
        guard let spaceService = notification.object as? MXSpaceService else {
            return
        }
        
        trackSpaceNumber(with: spaceService)
    }
    
    // MARK: - Private
    
    private func trackSpaceNumber(with spaceService: MXSpaceService) {
        let spaceNumber = spaceService.spaceSummaries.filter { $0.membership == .join }.count
        
        guard lastNumberOfSpaces != spaceNumber else {
            return
        }
        
        Analytics.shared.updateUserProperties(numSpaces: spaceNumber)
        lastNumberOfSpaces = spaceNumber
    }
}
