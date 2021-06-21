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

import UIKit

/// Fonts at  https://www.figma.com/file/X4XTH9iS2KGJ2wFKDqkyed/Compound?node-id=1362%3A0
@objcMembers
public class ElementFonts: Fonts {
    
    // MARK: - Setup
    
    public init() {
    }
    
    // MARK: - Public
    
    /// Returns an instance of the font associated with the text style and scaled appropriately for the content size category defined in the trait collection.
    public func font(forTextStyle textStyle: UIFont.TextStyle, compatibleWith traitCollection: UITraitCollection?) -> UIFont {
        return UIFont.preferredFont(forTextStyle: textStyle, compatibleWith: traitCollection)
    }
    
    // MARK: TextStyle shortcuts
    
    public var largeTitle: UIFont {
        return self.font(forTextStyle: .largeTitle)
    }
            
    public var title1: UIFont {
        return self.font(forTextStyle: .title1)
    }
    
    public var title2: UIFont {
        return self.font(forTextStyle: .title2)
    }
    
    public var title3: UIFont {
        return self.font(forTextStyle: .title3)
    }
    
    public var headline: UIFont {
        return self.font(forTextStyle: .headline)
    }
    
    public var subheadline: UIFont {
        return self.font(forTextStyle: .subheadline)
    }
    
    public var body: UIFont {
        return self.font(forTextStyle: .body)
    }
    
    public var callout: UIFont {
        return self.font(forTextStyle: .callout)
    }
    
    public var caption1: UIFont {
        return self.font(forTextStyle: .caption1)
    }
    
    public var caption2: UIFont {
        return self.font(forTextStyle: .caption2)
    }
}
