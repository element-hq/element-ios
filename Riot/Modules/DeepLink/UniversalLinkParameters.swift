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
        
    /// The unprocessed the universal link URL
    let universalLinkURL: URL
    
    /// The fragment part of the universal link
    let fragment: String
        
    /// Presentation parameters
    let presentationParameters: ScreenPresentationParameters
    
    // MARK: - Setup
    
    init(fragment: String,
         universalLinkURL: URL,
         presentationParameters: ScreenPresentationParameters) {
        self.fragment = fragment
        self.universalLinkURL = universalLinkURL
        self.presentationParameters = presentationParameters
        
        super.init()
    }
    
    convenience init?(universalLinkURL: URL,
                      presentationParameters: ScreenPresentationParameters) {
        
        guard let fixedURL = Tools.fixURL(withSeveralHashKeys: universalLinkURL), let fragment = fixedURL.fragment else {
            return nil
        }
        
        self.init(fragment: fragment, universalLinkURL: universalLinkURL, presentationParameters: presentationParameters)
    }
}
