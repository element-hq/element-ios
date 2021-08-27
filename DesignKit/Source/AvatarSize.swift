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

// Figma Avatar Sizes: https://www.figma.com/file/X4XTH9iS2KGJ2wFKDqkyed/Compound?node-id=1258%3A19678
public enum AvatarSize: Int {
    case xxSmall = 16
    case xSmall = 32
    case small = 36
    case medium = 42
    case large = 44
    case xLarge = 52
    case xxLarge = 80
}

extension AvatarSize {
    public var size: CGSize {
        return CGSize(width: self.rawValue, height: self.rawValue)
    }
}
