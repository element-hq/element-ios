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

/// A subclass of `UITableViewHeaderFooterView` that conforms `Themable`
/// to create a consistent looking custom footer inside of the app. If using gesture
/// recognizers on the view, be aware that these will be automatically removed on reuse.
@objcMembers
class SectionFooterView: UITableViewHeaderFooterView, Themable {
    static var defaultReuseIdentifier: String {
        String(describing: Self.self)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        for recognizer in gestureRecognizers ?? [] {
            removeGestureRecognizer(recognizer)
        }
    }
    
    func update(theme: Theme) {
        textLabel?.textColor = theme.colors.secondaryContent
        textLabel?.font = theme.fonts.subheadline
        textLabel?.numberOfLines = 0
    }
}
