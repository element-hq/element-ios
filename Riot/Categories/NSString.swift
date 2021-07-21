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

extension NSString {
    /// Check if the string contains a URL.
    /// - Returns: True if the string contains at least one URL, otherwise false.
    @objc func vc_containsURL() -> Bool {
        guard let linkDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            MXLog.debug("[NSString+URLDetector]: Unable to create link detector.")
            return false
        }
        
        // return true if there is at least one match
        return linkDetector.numberOfMatches(in: self as String, options: [], range: NSRange(location: 0, length: self.length)) > 0
    }
    
    /// Gets the first URL contained in the string.
    /// - Returns: A URL if detected, otherwise nil.
    @objc func vc_firstURLDetected() -> NSURL? {
        guard let linkDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            MXLog.debug("[NSString+URLDetector]: Unable to create link detector.")
            return nil
        }
        
        // find the first match, otherwise return nil
        guard let match = linkDetector.firstMatch(in: self as String, options: [], range: NSRange(location: 0, length: self.length)) else {
            return nil
        }
        
        // create a url and return it.
        let urlString = self.substring(with: match.range)
        return NSURL(string: urlString)
    }
}
