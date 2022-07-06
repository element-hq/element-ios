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

/// Parameters describing a universal link
@objcMembers
class UniversalLinkParameters: NSObject {
        
    // MARK: - Properties
        
    /// The universal link
    let universalLink: UniversalLink
    
    /// The fragment part of the universal link
    let fragment: String
        
    /// Presentation parameters
    let presentationParameters: ScreenPresentationParameters
    
    // MARK: - Setup
    
    init(fragment: String,
         universalLink: UniversalLink,
         presentationParameters: ScreenPresentationParameters) {
        self.fragment = fragment
        self.universalLink = universalLink
        self.presentationParameters = presentationParameters
        
        super.init()
    }
    
    convenience init?(universalLink: UniversalLink,
                      presentationParameters: ScreenPresentationParameters) {
        
        guard let fixedURL = Tools.fixURL(withSeveralHashKeys: universalLink.url), let fragment = fixedURL.fragment else {
            return nil
        }
        
        self.init(fragment: fragment, universalLink: universalLink, presentationParameters: presentationParameters)
    }

    convenience init?(url: URL,
                      presentationParameters: ScreenPresentationParameters) {

        guard let fixedURL = Tools.fixURL(withSeveralHashKeys: url), let fragment = fixedURL.fragment else {
            return nil
        }
        let universalLink = UniversalLink(url: fixedURL)

        self.init(fragment: fragment, universalLink: universalLink, presentationParameters: presentationParameters)
    }
}
