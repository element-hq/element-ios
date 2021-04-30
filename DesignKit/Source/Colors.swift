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

/// Colors at https://www.figma.com/file/X4XTH9iS2KGJ2wFKDqkyed/Compound?node-id=1255%3A1104
@objc public protocol Colors {
    
    var accent: UIColor { get }
    
    var alert: UIColor { get }
    
    var primaryContent: UIColor { get }
    
    var secondaryContent: UIColor { get }
    
    var tertiaryContent: UIColor { get }
    
    var quarterlyContent: UIColor { get }
    
    var separator: UIColor { get }
    
    var toast: UIColor { get }
    
    var tile: UIColor { get }
    
    var navigation: UIColor { get }
    
    var background: UIColor { get }
    
    var namesAndAvatars: [UIColor] { get }
    
}
