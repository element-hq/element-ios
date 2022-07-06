// 
// Copyright 2020 The Matrix.org Foundation C.I.C
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
import MatrixSDK.MXLog

public extension NSString {

    /// Gets the first URL contained in the string ignoring any links to hosts defined in
    /// the `firstURLDetectionIgnoredHosts` property of `MXKAppSettings`.
    /// - Returns: A URL if detected, otherwise nil.
    @objc func mxk_firstURLDetected() -> NSURL? {
        let hosts = MXKAppSettings.standard().firstURLDetectionIgnoredHosts ?? []
        return mxk_firstURLDetected(ignoring: hosts)
    }
    
    /// Gets the first URL contained in the string ignoring any links to the specified hosts.
    /// - Returns: A URL if detected, otherwise nil.
    @objc func mxk_firstURLDetected(ignoring ignoredHosts: [String]) -> NSURL? {
        guard let linkDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            MXLog.debug("[NSString+URLDetector]: Unable to create link detector.")
            return nil
        }
        
        var detectedURL: NSURL?
        
        // enumerate all urls that were found in the string to ensure
        // detection of a valid link if there are invalid links preceding it
        linkDetector.enumerateMatches(in: self as String,
                                      options: [],
                                      range: NSRange(location: 0, length: self.length)) { match, flags, stop in
            guard let match = match else { return }
            
            // check if the match is a valid url
            let urlString = self.substring(with: match.range)
            guard let url = NSURL(string: urlString) else { return }
            
            // ensure the match is a web link
            guard let scheme = url.scheme?.lowercased(),
                  scheme == "https" || scheme == "http"
            else { return }
            
            // discard any links to ignored hosts
            guard let host = url.host?.lowercased(),
                  !ignoredHosts.contains(host)
            else { return }
            
            detectedURL = url
            stop.pointee = true
        }
        
        return detectedURL
    }
}
