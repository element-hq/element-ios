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

@objcMembers
final class FormattedBodyParser: NSObject {
    
    private var formattedBody: String
    
    /// Initialize parser
    /// - Parameter formattedBody: html formatted body
    init(withFormattedBody formattedBody: String) {
        self.formattedBody = formattedBody
    }
    
    /// Gets visible url for a given url. Assumes formattedBody has a link like: '<a href="https://example.com/given">https://example.com/visible</a>'
    /// - Parameter url: the url given as target
    /// - Returns: visible url if found, otherwise nil
    func getVisibleURL(forURL url: URL) -> URL? {
        let rangeOfLink = (formattedBody as NSString).range(of: String(format: "href=\"%@\"", url.absoluteString))
        if rangeOfLink.location != NSNotFound {
            let rangeAfterLink = NSRange(location: rangeOfLink.upperBound, length: formattedBody.count - rangeOfLink.upperBound)
            var startOfVisibleLink = NSNotFound
            var endOfVisibleLink = NSNotFound

            //  try to find the beginning
            let rangeOfLinkBeginning = (formattedBody as NSString).range(of: ">", range: rangeAfterLink)
            if rangeOfLinkBeginning.location != NSNotFound {
                startOfVisibleLink = rangeOfLinkBeginning.upperBound
            } else {
                return nil
            }
            
            //  try to find the end
            let rangeOfLinkEnd = (formattedBody as NSString).range(of: "</a>", range: rangeAfterLink)
            if rangeOfLinkEnd.location != NSNotFound {
                endOfVisibleLink = rangeOfLinkEnd.location
            } else {
                return nil
            }

            if startOfVisibleLink != NSNotFound && endOfVisibleLink != NSNotFound {
                //  get the visible link
                let rangeOfVisibleLink = NSRange(location: startOfVisibleLink, length: endOfVisibleLink - startOfVisibleLink)
                let visibleLink = (formattedBody as NSString).substring(with: rangeOfVisibleLink)
                return URL(string: visibleLink)
            }
        }
        return nil
    }
    
}
