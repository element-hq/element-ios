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

/// Describe Fonts
@objc public protocol Fonts {
    
    /// Returns an instance of the font associated with the text style and scaled appropriately for the content size category defined in the trait collection.
    func font(forTextStyle textStyle: UIFont.TextStyle, compatibleWith traitCollection: UITraitCollection?) -> UIFont

    // MARK: - TextStyle shortcuts
    
    var largeTitle: UIFont { get }
    var title1: UIFont { get }
    var title2: UIFont { get }
    var title3: UIFont { get }
    var headline: UIFont { get }
    var subheadline: UIFont { get }
    var body: UIFont { get }
    var callout: UIFont { get }
    var caption1: UIFont { get }
    var caption2: UIFont { get }
}

// MARK: - Default implementation
extension Fonts {
    
    /// Returns an instance of the font associated with the text style and scaled appropriately for the user's selected content size category.
    func font(forTextStyle textStyle: UIFont.TextStyle) -> UIFont {
        return self.font(forTextStyle: textStyle, compatibleWith: nil)
    }
}
