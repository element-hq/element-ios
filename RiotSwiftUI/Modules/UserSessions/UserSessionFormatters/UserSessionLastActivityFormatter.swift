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

/// Enables to build last activity date string
class UserSessionLastActivityFormatter {
    
    // MARK: - Constants
    
    private static var lastActivityDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }()
    
    // MARK: - Public
    
    /// Session last activity string
    func lastActivityDateString(from lastActivityTimestamp: TimeInterval) -> String {
        
        let date = Date(timeIntervalSince1970: lastActivityTimestamp)
        
        return UserSessionLastActivityFormatter.lastActivityDateFormatter.string(from: date)
    }
}
