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
import UIKit

/// Theme v2. May be named again as `Theme` when the migration completed.
@objc public protocol ThemeV2 {
    
    /// Colors object
    var colors: ColorsUIKit { get }
    
    /// Fonts object
    var fonts: FontsUIKit { get }
    
    /// may contain more design components in future, like icons, audio files etc.
}

/// Theme v2 for SwiftUI.
public protocol ThemeSwiftUIType {
    
    /// Colors object
    var colors: ColorSwiftUI { get }
    
    /// Fonts object
    var fonts: FontSwiftUI { get }
    
    /// may contain more design components in future, like icons, audio files etc.
}
