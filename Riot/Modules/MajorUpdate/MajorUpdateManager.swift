/*
 Copyright 2020 New Vector Ltd
 
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

/// `MajorUpdateManager` is used to indicate if a major update alert should be displayed.
@objcMembers
final public class MajorUpdateManager: NSObject {
    
    // MARK: - Constants
    
    private enum Constants {
        static var lastMajorAppVersion = AppVersion(bundleShortVersion: "1.0.0", bundleVersion: "0")
        static var learnMoreStringURL = "https://element.io/previously-riot"
    }
    
    // MARK: - Properties
    
    var shouldShowMajorUpdate: Bool {
        guard let lastUsedAppVersion = AppVersion.lastUsed else {
            MXLog.debug("[MajorUpdateManager] shouldShowMajorUpdate: Unknown previous version")
            return false
        }
        
        let shouldShowMajorUpdate = (lastUsedAppVersion.compare(Constants.lastMajorAppVersion) == .orderedAscending)
        MXLog.debug("[MajorUpdateManager] shouldShowMajorUpdate: \(shouldShowMajorUpdate). AppVersion.lastUsed: \(lastUsedAppVersion). lastMajorAppVersion: \(Constants.lastMajorAppVersion)")
        
        return shouldShowMajorUpdate
    }
    
    var learnMoreURL: URL {
        guard let url = URL(string: Constants.learnMoreStringURL) else {
            fatalError("[MajorUpdateManager] learn more URL should be valid")
        }
        return url
    }
}
